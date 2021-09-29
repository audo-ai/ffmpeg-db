#include <functional>
#include <map>
#include <set>
#include <sstream>
#include <string>

void serializeJson(std::stringstream &ss, const std::string &str) {
    ss << "\"" << str << "\"";
}
void serializeJson(std::stringstream &ss, const char *str) {
    serializeJson(ss, std::string(str));
}

void removeComma(std::stringstream &ss) {
    auto orig = ss.tellg();
    ss.seekg(-1, std::ios::end);
    char c;
    ss >> c;
    ss.seekg(orig);
    if (c == ',') {
        ss.seekp(-1, ss.cur);
    }
}

template <typename T>
void serializeJson(std::stringstream &ss, const std::set<T> &obj) {
    ss << "[";
    for (auto j : obj) {
        serializeJson(ss, j);
        ss << ",";
    }
    removeComma(ss);
    ss << "]";
}

template <typename T>
void serializeJson(std::stringstream &ss, const std::map<std::string, T> &obj) {
    ss << "{";
    for (auto i : obj) {
        serializeJson(ss, i.first);
        ss << ":";
        serializeJson(ss, i.second);
        ss << ",";
    }
    removeComma(ss);
    ss << "}";
}

template <typename Func>
void serializeManualDict(std::stringstream &ss, Func func) {
    ss << '{';
    func();
    removeComma(ss);
    ss << '}';
}

template <typename T>
void manualDictEntry(std::stringstream &ss, const std::string &key,
                     const T &t) {
    serializeJson(ss, key);
    ss << ":";
    serializeJson(ss, t);
    ss << ",";
}

template <typename Func>
void manualDictEntryFunc(std::stringstream &ss, const std::string &key,
                         Func func) {
    serializeJson(ss, key);
    ss << ":";
    func();
    ss << ",";
}

template <typename Iter, typename Func>
void serializeIter(std::stringstream &ss, Iter begin, Iter end, char cBegin,
                   char cEnd, Func func) {
    ss << cBegin;
    for (Iter it = begin; it != end; ++it) {
        func(it);
    }
    removeComma(ss);
    ss << cEnd;
}

template <typename T>
std::string toJson(const T &val) {
    std::stringstream ss;
    serializeJson(ss, val);
    return ss.str();
}
