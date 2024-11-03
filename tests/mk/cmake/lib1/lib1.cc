
#include <iostream>
#include <concepts>

template <typename T>
concept IsIntegral = std::is_integral_v<T>;

void print_integral(IsIntegral auto value) {
    std::cout << "Value: " << value << std::endl;
}

int main() {
    print_integral(42);
    // print_integral(3.14); // error
}
