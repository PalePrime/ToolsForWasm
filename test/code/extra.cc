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
    int pin_cnt = 0;
};

struct expr_info {
    vector<string> vars;
    int bits = 1;
    int value = 0;
    int inv_cnt = 0;
    int gate_cnt = 0;
    int complex_cnt = 0;
    int pin_cnt = 0;    
};

struct mod_info {
    string name;
    string addr;
    vector<inst_info> instances;
    vector<assign_info> assigns;
    int always_cnt = 0;
    int assign_cnt = 0;
    int inv_cnt = 0;
    int gate_cnt = 0;
    int complex_cnt = 0;
    int instance_cnt = 0;
};

map<string, json> modules;
map<string, mod_info> modInfo;

void parseExpression(json e, expr_info *e_info) {
    if (e.size() != 1) {
        if (e.size() > 1) cout << "Bad expression!\n";
    } else {
        json expr = e[0];
        string e_name = (string)expr["name"];
        string e_type = (string)expr["type"];
        int l_bits, r_bits = 1;
        if (e_type == "AND" || e_type == "OR" || e_type == "XOR") {
            parseExpression(expr["lhsp"], e_info);
            l_bits = e_info->bits;
            parseExpression(expr["rhsp"], e_info);
            r_bits = e_info->bits;
            if (l_bits != r_bits) cout << "Expression has unbalanced width!\n";
            e_info->gate_cnt += l_bits;
        } else if (e_type == "NOT") {
            parseExpression(expr["lhsp"], e_info);
            e_info->inv_cnt += e_info->bits;
        } else if (e_type == "PARSEREF") {
            e_info->vars.push_back((string)expr["name"]);
        } else if (e_type == "CONST") {
            regex r = regex("(\\d+)$");
            string a_value = (string)expr["name"];
            smatch m;
            regex_search(a_value, m, r);
            int value = -1;
            if (m.length()>0) {
                auto& t_value = m[0];
                value = atoi(t_value.first.base());
            }
            e_info->value = value;
        } else if (e_type == "SELBIT") {
            expr_info b_info;
            parseExpression(expr["bitp"], &b_info);
            parseExpression(expr["fromp"], &b_info);
            for (string v : b_info.vars) {
                string name = v.append("[").append(to_string(b_info.value)).append("]");
                e_info->vars.push_back(name);
            }
        } else if (e_type == "SELEXTRACT") {
            expr_info b_info;
            int left, right = 0;
            parseExpression(expr["fromp"], &b_info);
            parseExpression(expr["leftp"], &b_info);
            left = b_info.value;
            parseExpression(expr["rightp"], &b_info);
            right = b_info.value;
            e_info->bits = abs(left-right) + 1;
            for (string v : b_info.vars) {
                string name = v.append("[").append(to_string(left)).append(":").append(to_string(right)).append("]");
                e_info->vars.push_back(name);
            }
        } else {
            parseExpression(expr["lhsp"], e_info);
            l_bits = e_info->bits;
            parseExpression(expr["rhsp"], e_info);
            r_bits = e_info->bits;
            if (l_bits != r_bits) cout << "Expression has unbalanced width!\n";
            e_info->complex_cnt += l_bits;
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

    cout << "Module count: " << module_count << '\n';

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
                parseExpression(lhs, &l_info);

                expr_info e_info;
                parseExpression(rhs, &e_info);

                info.gate_cnt += e_info.gate_cnt;
                info.complex_cnt += e_info.complex_cnt;
                a_info.inv_cnt = e_info.inv_cnt;
                a_info.gate_cnt = e_info.gate_cnt;
                a_info.complex_cnt = e_info.complex_cnt;
                a_info.bits = e_info.bits;
                a_info.vars = e_info.vars;

                a_info.name = l_info.vars.size()>0 ? l_info.vars[0] : "?";
                info.assigns.push_back(a_info);
            } else if (s_type == "ALWAYS") {
                info.always_cnt++;
            }
        }
        modInfo[info.name] = info;
    }

}

int moduleExists(const char* name) {
    const string n = string(name);
    return modInfo.count(n);
}

int gateCount(const char* name) {
    int result = 0;
    const string n = string(name);
    mod_info info = modInfo[name];
    if (n == info.name) {
        result = info.gate_cnt;
    } else {
        cout << "  Module " << n << " not found when obtaining gates count!\n";
        result = -1;
    }
    return result;
}

int onlyAssigns(const char* name) {
    int result = 0;
    const string n = string(name);
    mod_info info = modInfo[name];
    if (n == info.name) {
        if (info.always_cnt == 0 && info.instance_cnt == 0) result = 1;
    } else {
        cout << "  Module " << n << " not found when checking for assigns only!\n";
        result = -1;
    }
    return result;
}

int onlyGates(const char* name) {
    int result = 0;
    const string n = string(name);
    mod_info info = modInfo[name];
    if (n == info.name) {
        if (info.always_cnt == 0 && info.instance_cnt == 0 && info.complex_cnt == 0) result = 1;
    } else {
        cout << "  Module " << n << " not found when checking for gates only!\n";
        result = -1;
    }
    return result;
}

void printStats(const char* name) {
    string n = string(name);
    mod_info info = modInfo[name];
    cout << "Module " << n << ":\n";
    if (n == info.name) {
        cout << "  Assigns:      " << info.assign_cnt << "\n";
        for (auto a : info.assigns) {
            cout << "    " << a.name << " width: " << a.bits ;
            cout << " using: " << a.inv_cnt << "/" << a.gate_cnt << "/" << a.complex_cnt << " inverters/gates/others";
            cout << " from";
            for (auto v : a.vars) {
                cout << " " << v;
            }
            cout << "\n";
        }
        cout << "  Always:       " << info.always_cnt << "\n";
        cout << "  Instances:    " << info.instance_cnt << "\n";
        for (auto i : info.instances) {
            cout << "    " << i.name << " of " << i.mod_name << "\n";
        }
        cout << "  Inverters:    " << info.inv_cnt << "\n";
        cout << "  Gates:        " << info.gate_cnt << "\n";
        cout << "  Other ops:    " << info.complex_cnt << "\n";
    } else {
        cout << "  No such module found in the design!\n";
    }
}