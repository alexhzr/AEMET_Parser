#include <map>
#include <string>
#include <iostream>
#include "provincia.h"
#include "localidad.h"

using namespace std;

Provincia::Provincia(string codigo, string nombre) {
	this->codigo = codigo;
	this->nombre = nombre;
}

void Provincia::addLocalidad(string codigo, string nombre) {
	Localidad l(codigo, nombre);
	localidades.insert(make_pair(codigo, l));
}

void Provincia::imprimirLocalidades() {
	map<string, Localidad>::iterator it = localidades.begin();

	for (it; it != localidades.end(); ++it) {
		cout << it->first << " - " << it->second.nombre << endl;
	}

}
