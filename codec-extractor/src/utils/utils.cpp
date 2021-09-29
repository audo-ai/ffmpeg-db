#include <sstream>
#include <string>
#include <vector>

using std::string;
using std::stringstream;
using std::vector;

vector<string> splitStr(const string &s, char c) {
    vector<string> parts;
    stringstream ss(s);
    while (ss.good()) {
        string rawExt;
        getline(ss, rawExt, c);
        auto extBegin = rawExt.begin();
        auto extEnd = rawExt.rbegin();
        while (std::isspace(*extBegin)) ++extBegin;
        while (std::isspace(*extEnd)) ++extEnd;
        string ext(extBegin, extEnd.base());
        parts.emplace_back(ext);
    }
    return parts;
}