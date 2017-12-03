#ifndef _PROVINCIA_H
#define _PROVINCIA_H

#include <map>
#include <iostream>
#include <string>
#include "localidad.h"

using namespace std;

class Provincia {
	public:
		string nombre;
		string codigo;
		map<string, Localidad> localidades;

		Provincia(string codigo, string nombre);
		void addLocalidad(string codigo, string nombre);
		void imprimirLocalidades();
};

#endif