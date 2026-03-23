#include <stdio.h>
#include <string.h>

double GreetingsNativeFunc(const char* name, double num)
{
  printf("Greetings, %s\n", name);
  return strlen(name) * num;
}
