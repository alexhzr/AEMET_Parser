#ifndef _LOCALIDAD_H
#define _LOCALIDAD_H

#include <string>
#include <iostream>

using namespace std;

class Localidad {
	public:
		string nombre;
		string codigo;

		Localidad(string codigo, string nombre);

};

#endif