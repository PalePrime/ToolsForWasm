#include "stdint.h"
#include "svdpi.h"

extern "C" {
    extern void gatherStats();
    extern int moduleExists(const char* name);
    extern int gateCount(const char* name);
    extern int onlyAssigns(const char* name);
    extern int onlyGates(const char* name);
    extern void printStats(const char* name);
    extern int hashMe();
}

#include <filesystem>
#include <iostream>
#include <fstream>
#include <regex>
#include <set>

#include "json.hpp"

namespace fs = std::filesystem;
using json = nlohmann::json;
using namespace std;

string callingFile() {
    const char* filenamep = "";
    int lineno = 0;
    if(!svGetCallerInfo(&filenamep, &lineno)) {
        cout << "Failed to determine calling file name \n";
    }
    return string(filenamep);
}

int hashMe() {
    const string filename = callingFile();
    fs::path thePath{filename} ;
    int lineno = 0;
    int theHash = 42;
    if (filename.size()>0 && fs::exists(thePath)) {
        cout << "Computing hash for file " << filename << "\n";
        ifstream file(filename);
        while(!file.eof()) {
            int c = file.get();
            theHash = 17 * theHash + c + (c << 8) + (c << 16) + (c << 24);
        }
        return theHash;
    } else {
        cout << "Cannot compute hash for non-existing file " << filename << "\n";
        return 0;
    }
}

struct inst_info {
    string name;
    string mod_name;
};

struct assign_info {
    string name;
    vector<string> vars;
    int bits = 1;
    int inv_cnt = 0;
    int gate_cnt = 0;
    int complex_cnt = 0;
};

struct expr_info {
    vector<string> vars;
    int bits = 1;
    int value = 0;
    int inv_cnt = 0;
    int gate_cnt = 0;
    int complex_cnt = 0;
};

struct var_info {
    string name;
    int bits = 1;
};

struct mod_info {
    string name;
    string addr;
    vector<inst_info> instances;
    map<string, var_info> variables;
    vector<assign_info> assigns;
    int assign_cnt = 0;
    int instance_cnt = 0;
    int other_cnt = 0;
    int inv_cnt = 0;
    int gate_cnt = 0;
    int complex_cnt = 0;
    int var_cnt = 0;
    int port_cnt = 0;
};

map<string, json> modules;
map<string, mod_info> modInfo;

void checkBalance(string op, expr_info *l_info, expr_info *r_info) {
    int l_bits = l_info->bits;
    int r_bits = r_info->bits;
    if (l_bits && r_bits && l_bits != r_bits) {
        cout << "Operator " << op << " has unbalanced width!\n";
        cout << "  Left width:  " << l_bits << " from";
        for (auto v : l_info->vars) {
            cout << " " << v;
        }
        cout << "\n";
        cout << "  Right width: " << r_bits << " from";
        for (auto v : r_info->vars) {
            cout << " " << v;
        }
        cout << "\n\n";
    }
}

void propagateResults(expr_info *e_info, expr_info *l_info, expr_info *r_info) {
    if (l_info != nullptr) {
        e_info->inv_cnt += l_info->inv_cnt;
        e_info->gate_cnt += l_info->gate_cnt;
        e_info->complex_cnt += l_info->complex_cnt;
    }
    if (r_info != nullptr) {
        e_info->inv_cnt += r_info->inv_cnt;
        e_info->gate_cnt += r_info->gate_cnt;
        e_info->complex_cnt += r_info->complex_cnt;
    } 
}

void parseExpression(json e, expr_info *e_info, mod_info *m_info) {
    if (e.size() != 1) {
        if (e.size() > 1) cout << "Bad expression!\n";
    } else {
        json expr = e[0];
        string e_name = (string)expr["name"];
        string e_type = (string)expr["type"];
        if (e_type == "NOT") {
            expr_info l_info;
            parseExpression(expr["lhsp"], &l_info, m_info);
            propagateResults(e_info, &l_info, nullptr);
            e_info->bits = l_info.bits;
            e_info->inv_cnt += l_info.bits;
        } else if (e_type == "PARSEREF") {
            string name = (string)expr["name"];
            var_info v_info = m_info->variables[name];
            e_info->bits = v_info.bits;
            e_info->vars.push_back(name);
        } else if (e_type == "CONST") {
            regex r = regex("h([0-9a-fA-F]*)$");
            string a_value = (string)expr["name"];
            smatch m;
            regex_search(a_value, m, r);
            int value = -1;
            if (m.length()>1) {
                auto& t_value = m[1];
                value = stoul(t_value.first.base(), nullptr, 16);
                e_info->vars.push_back(string("\"").append(to_string(value).append("\"")));
            }
            e_info->bits = 0;
            e_info->value = value;
        } else if (e_type == "SELBIT") {
            expr_info b_info, i_info;
            parseExpression(expr["bitp"], &i_info, m_info);
            parseExpression(expr["fromp"], &b_info, m_info);
            for (string v : b_info.vars) {
                string name = v.append("[").append(to_string(i_info.value)).append("]");
                e_info->vars.push_back(name);
            }
            propagateResults(e_info, &b_info, nullptr);
            e_info->bits = 1;
        } else if (e_type == "SELEXTRACT" || e_type == "RANGE") {
            expr_info b_info, i_info;
            int left, right = 0;
            parseExpression(expr["fromp"], &b_info, m_info);
            parseExpression(expr["leftp"], &i_info, m_info);
            left = max(i_info.value, 0);
            parseExpression(expr["rightp"], &i_info, m_info);
            right = i_info.value<0 ? 999 : i_info.value;
            for (string v : b_info.vars) {
                string name = v.append("[").append(to_string(left)).append(":").append(to_string(right)).append("]");
                e_info->vars.push_back(name);
            }
            propagateResults(e_info, &b_info, nullptr);
            e_info->bits = abs(left-right) + 1;
        } else if (e_type == "REPLICATE") {
            expr_info b_info, i_info;
            int count = 0;
            parseExpression(expr["srcp"], &b_info, m_info);
            parseExpression(expr["countp"], &i_info, m_info);
            count = i_info.value<0 ? 999 : i_info.value;
            for (string v : b_info.vars) {
                e_info->vars.push_back(v);
            }
            propagateResults(e_info, &b_info, nullptr);
            e_info->bits = b_info.bits * count;
        } else if (e_type == "CONCAT") {
            expr_info l_info, r_info;
            string name = "{";
            parseExpression(expr["lhsp"], &l_info, m_info);
            parseExpression(expr["rhsp"], &r_info, m_info);
            for (string v : l_info.vars) {
                name.append(v);
            }
            name.append(", ");
            for (string v : r_info.vars) {
                name.append(v);
            }
            e_info->vars.push_back(name.append("}"));
            propagateResults(e_info, &l_info, &r_info);
            e_info->bits = abs(l_info.bits+r_info.bits);
        } else if (e_type.find(string("RED")) == 0) {
            expr_info l_info;
            parseExpression(expr["lhsp"], &l_info, m_info);
            propagateResults(e_info, &l_info, nullptr);
            e_info->bits = 1;
            if (e_type == "REDAND" || e_type == "REDOR" || e_type == "REDXOR") {
                e_info->gate_cnt += l_info.bits - 1;
            } else {
                e_info->complex_cnt += l_info.bits - 1;
            }
        } else {
            expr_info l_info, r_info;
            int bits = 0;
            parseExpression(expr["lhsp"], &l_info, m_info);
            parseExpression(expr["rhsp"], &r_info, m_info);
            checkBalance(e_type, &l_info, &r_info);
            for (string v : l_info.vars) {
                e_info->vars.push_back(v);
            }
            for (string v : r_info.vars) {
                e_info->vars.push_back(v);
            }
            propagateResults(e_info, &l_info, &r_info);
            bits = max(l_info.bits, r_info.bits);
            e_info->bits = bits;
            if (e_type == "AND" || e_type == "OR" || e_type == "XOR") {
                e_info->gate_cnt += bits;
            } else {
                e_info->complex_cnt += bits;
            }
        }
    }
} 

void gatherStats() {
    json j;
    const string file = "obj_dir/top_002_cellsort.tree.json";

    fs::path thePath{file};


    if (fs::exists(thePath)) {
        fstream j_file(file);
        j_file >> j;
    } else {
        cout << "Failed to load Verilator parse tree from " << file << "\n";
        j = {"failure", true};
    }

    auto module_count = j["modulesp"].size();

    for (json m : j["modulesp"]) {
        auto addr = (string)m["addr"];
        modules[addr] = m;
    }

    for (auto m : modules) {
        auto mod = m.second;
        mod_info info;
        info.name = (string)mod["name"];
        auto stmts = mod["stmtsp"];
        for (json s : stmts) {
            string s_name = (string)s["name"];
            string s_type = (string)s["type"];
            if (s_type == "CELL") {
                inst_info i_info;
                info.instance_cnt++;
                auto i_addr = (string)s["modp"];
                i_info.name = s_name;
                i_info.mod_name = (string)modules[i_addr]["name"];
                info.instances.push_back(i_info);
            } else if (s_type == "ASSIGN" || s_type == "ASSIGNW" ) {
                assign_info a_info;
                int gate_cnt = 0;
                info.assign_cnt++;
                json lhs = s["lhsp"];
                json rhs = s["rhsp"];

                expr_info l_info;
                parseExpression(lhs, &l_info, &info);

                expr_info e_info;
                parseExpression(rhs, &e_info, &info);
                // checkBalance(s_type, &l_info, &e_info);

                info.inv_cnt += e_info.inv_cnt;
                info.gate_cnt += e_info.gate_cnt;
                info.complex_cnt += e_info.complex_cnt;
                a_info.inv_cnt = e_info.inv_cnt;
                a_info.gate_cnt = e_info.gate_cnt;
                a_info.complex_cnt = e_info.complex_cnt;
                a_info.bits = max(l_info.bits, e_info.bits);
                a_info.vars = e_info.vars;

                a_info.name = l_info.vars.size()>0 ? l_info.vars[0] : "?";
                info.assigns.push_back(a_info);
            } else if (s_type == "VAR") {
                var_info v_info;
                v_info.name = s_name;
                expr_info e_info;
                parseExpression(s["childDTypep"][0]["rangep"], &e_info, &info);
                if (e_info.bits < 1) {
                    cout << "Can't determine bit width of variable " << s_name << " in module " << info.name << "\n";
                    v_info.bits = 999;
                } else {
                    v_info.bits = e_info.bits;
                }
                info.variables[s_name] = v_info;
                info.var_cnt++;
            } else if (s_type == "PORT") {
                info.port_cnt++;
                info.var_cnt--;
            } else {
                if (info.name != "main_tb") cout << "Unexpected statement " << s_type << " found in module " << info.name << "\n";
                info.other_cnt++;
            }
        }
        modInfo[info.name] = info;
    }

}

int moduleExists(const char* name) {
    const string n = string(name);
    return modInfo.count(n);
}

void doCount(mod_info *info, mod_info *count, set<string> *subs = nullptr) {
    count->assign_cnt   += info->assign_cnt   ;
    count->instance_cnt += info->instance_cnt ;
    count->other_cnt    += info->other_cnt    ;
    count->inv_cnt      += info->inv_cnt      ;
    count->gate_cnt     += info->gate_cnt     ;
    count->complex_cnt  += info->complex_cnt  ;
    for (auto i : info->instances) {
        mod_info m = modInfo[i.mod_name];
        if (subs != nullptr) {
            subs->insert(i.mod_name);
        }
        doCount(&m, count);
    }
}

int gateCount(const char* name) {
    int result = 0;
    const string n = string(name);
    mod_info info = modInfo[name];
    mod_info count;
    if (n == info.name) {
        doCount(&info, &count);
        result = count.gate_cnt;
    } else {
        cout << "Module " << n << " not found when obtaining gate count!\n";
        result = -1;
    }
    return result;
}

int onlyAssigns(const char* name) {
    int result = 1;
    const string n = string(name);
    mod_info info = modInfo[name];
    if (n == info.name) {
        if (info.other_cnt != 0) result = 0;
        for (auto i : info.instances) {
            if (!onlyAssigns(i.mod_name.c_str())) result = 0;
        }
    } else {
        cout << "Module " << n << " not found when checking for assigns only!\n";
        result = -1;
    }
    return result;
}

int onlyGates(const char* name) {
    int result = 1;
    const string n = string(name);
    mod_info info = modInfo[name];
    if (n == info.name) {
        if (info.other_cnt != 0 || info.complex_cnt != 0) result = 0;
        for (auto i : info.instances) {
            if (!onlyGates(i.mod_name.c_str())) result = 0;
        }
    } else {
        cout << "Module " << n << " not found when checking for gates only!\n";
        result = -1;
    }
    return result;
}

void printModStats(mod_info *info, const int ind = 0) {
    int i_cnt = info->instance_cnt;
    int i_cnt2 = 0;
    int a_cnt = info->assign_cnt;
    int a_cnt2 = 0;
    string indent = string("| ");
    for (int i=0; i < ind; i++) {
        indent += string("|  ");
    }
    // cout << indent << "Ports/Vars:       " << info->port_cnt << "/" << info->var_cnt << "\n";
    // for (auto v : info->variables) {
    //     cout << indent << "  " << v.second.name << " width: " << v.second.bits << "\n";
    // }
    if (i_cnt > 0) {
        cout << indent << "Instances:        " << i_cnt << "\n";
        for (auto i : info->instances) {
            mod_info count;
            doCount(&modInfo[i.mod_name], &count);
            if (count.inv_cnt + count.gate_cnt + count.complex_cnt > 0) {
                cout << indent << "  " << i.name << " of " << i.mod_name;
                cout << " using " << count.inv_cnt << "/" << count.gate_cnt << "/" << count.complex_cnt << " inverters/gates/other ops\n";
                i_cnt2++;
            }
        }
        if (i_cnt2 < i_cnt) {
            cout << indent << "  all " << (i_cnt2 != 0 ? "other " : "") << "instances represent wires only\n";
        }
    }
    if (a_cnt > 0) {
        cout << indent << "Assigns:          " << a_cnt << "\n";
        for (auto a : info->assigns) {
            if (a.inv_cnt + a.gate_cnt + a.complex_cnt > 0) {
                cout << indent << "  To " << a.name << " (width = " << a.bits ;
                cout << ") from";
                for (auto v : a.vars) {
                    cout << " " << v;
                }
                cout << " using " << a.inv_cnt << "/" << a.gate_cnt << "/" << a.complex_cnt << " inverters/gates/other ops\n";
                a_cnt2++;
            }
        }
        if (a_cnt2 < a_cnt) {
            cout << indent << "  all " << (a_cnt2 != 0 ? "other " : "") << "assignments represent wires only\n";
        }
    }
    if (info->other_cnt > 0) {
        cout << indent << "Other statements: " << info->other_cnt << "\n";
    }
    if (i_cnt + a_cnt + info->other_cnt == 0) {
        cout << indent << "No statements\n";
    }
}

void printStats(const char* name) {
    string n = string(name);
    mod_info info = modInfo[name];
    mod_info count;
    set<string> subs;
    cout << "Module " << n << " details:\n";
    if (n == info.name) {
        printModStats(&info, 0);
        cout << "+---\n";
        doCount(&info, &count, &subs);
        if (subs.size() > 0) {
            cout << "Module " << n << " has " << subs.size() << " submodules:\n";
            for (auto s : subs) {
                cout << "| Submodule " << s << ":\n";
                printModStats(&modInfo[s], 1);
                cout << "| +---\n";
            }
            cout << "+-----\n";
        }
        cout << "Module " << n << " totals:\n";
        cout << "| Inverters:        " << count.inv_cnt << "\n";
        cout << "| Gates:            " << count.gate_cnt << "\n";
        cout << "| Other operators:  " << count.complex_cnt << "\n";
        cout << "| Other statements: " << count.other_cnt << "\n";
        cout << "+---\n";
    } else {
        cout << "No such module found in the design!\n";
    }
}