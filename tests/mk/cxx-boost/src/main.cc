
#include <stdio.h>
#include <iostream>
#include <boost/regex.hpp>

int main() {
    std::string text = "Boost makes C++ easier!";
    boost::regex pattern("Boost");

    if (boost::regex_search(text, pattern)) {
        std::cout << "Pattern found!" << std::endl;
    } else {
        std::cout << "Pattern not found." << std::endl;
    }

    return 0;
}
