/** 
 *  @file    prediccion.l
 *  @author  Alejandro Hernández (alexhzr)
 *	@author  Miguel Toledo (miguel_toledo)
 *  @date    30/11/17  
 *  @version 1.0 
 *  
 *  @brief CSC 112, Lab 1, sorts strings using insertion sort
 *
 *  @section DESCRIPTION
 *  
 *  This is a little program that reads a list of names from
 *  a specified file or from standard input and then sorts
 *  the names in ascending order and prints them to standard
 *  output.
 *  
 *  Command line arguments are used to specify where the
 *  list of names should be read from.  If the program
 *  doesn't receive any command line arguments then it reads
 *  the names from standard input. If the program receives
 *  a single command line argument then it reads the names
 *  from the corresponding file.  If more than one command
 *  line argument is specified the program prints a usage
 *  message and terminates.
 *
 */

%{

#include <stdio.h>
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <iterator>

#include "restclient-cpp/restclient.h"
#include "restclient-cpp/connection.h"
#include "localidad.h"
#include "provincia.h"

using namespace RestClient;
using namespace std;

map<string, Provincia> provincias;
string nombre_provincia, nombre_localidad, codigo_provincia, codigo_localidad;
map<string, Provincia>::iterator it_provincia;
pair<map<string, Provincia>::iterator,bool> ret;

void imprimirListado(string c_prov);
void imprimirProvincias();
%}

%s NOMBRE_LOCALIDAD
%s NOMBRE_PROVINCIA
%s ID_PROVINCIA 
%s ID_LOCALIDAD
%s LEYENDO_LOCALIDADES

cualquier_nombre [a-zA-Z]+
id_localidad [0-9]{3}
id_provincia [0-5]{2}
label_nombre_localidad nombre_loc
label_id_localidad cmun
label_id_provincia cprov
label_nombre_provincia nombre_prov

%%

{label_id_provincia}							{ BEGIN(ID_PROVINCIA); }

<ID_PROVINCIA>{id_provincia} 					{ codigo_provincia = string(yytext); BEGIN(INITIAL); }

{label_nombre_provincia}						{ BEGIN(NOMBRE_PROVINCIA); }

<NOMBRE_PROVINCIA>{cualquier_nombre}			{ 
													nombre_provincia = string(yytext);
													Provincia p(codigo_provincia, nombre_provincia);

													//Esto es simplemente para tener una referencia a la provincia sobre
													//la que se van a añadir localidades
													ret = provincias.insert(make_pair(codigo_provincia, p));
													it_provincia = ret.first;

													BEGIN(LEYENDO_LOCALIDADES);
												}

<LEYENDO_LOCALIDADES>{label_id_localidad}		{ BEGIN(ID_LOCALIDAD); }

<ID_LOCALIDAD>{id_localidad} 					{ codigo_localidad = yytext; BEGIN(LEYENDO_LOCALIDADES); }

<LEYENDO_LOCALIDADES>{label_nombre_localidad}	{ BEGIN(NOMBRE_LOCALIDAD); }

<NOMBRE_LOCALIDAD>{cualquier_nombre}			{ 
													nombre_localidad = yytext;
													it_provincia->second.addLocalidad(codigo_localidad, nombre_localidad);

													BEGIN(LEYENDO_LOCALIDADES);
												}

<LEYENDO_LOCALIDADES>]							{ BEGIN(INITIAL); }

.	{}
\n 	{}

%%



int main(int argc, char *argv[]) {
	yyin = fopen("localidades_prueba.json", "rt");
	if (yyin == NULL) {
		printf("El fichero %s no se puede abrir\n", argv[1]);
		exit(-1);
	}

	yylex();

	string prov_selecc;
	int c_prov;

	do {
		cout << string(50, '\n');
		imprimirProvincias();
		cout << "\nIntroduzca el código de la provincia: ";
		cin >> prov_selecc;
		c_prov = stoi(prov_selecc);
	} while (c_prov < 1 || c_prov > 52);

	do {
		cout << string(50, '\n');
		imprimirListado(prov_selecc);
		cout << "\nIntroduzca el código de la localidad: ";
		cin >> prov_selecc;
		c_prov = stoi(prov_selecc);
	} while (false);


	/*string base_url = "https://opendata.aemet.es/opendata/api/";
	string api_key = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGVqYW5kcm9oZXJuYW5kZXpyZWNpb0BnbWFpbC5jb20iLCJqdGkiOiIwZjA5M2VmNi1hMmRlLTQ4ZTYtODdkNC0wZmM3ZTIxYjc3NTUiLCJpc3MiOiJBRU1FVCIsImlhdCI6MTUwOTk4MjU4NCwidXNlcklkIjoiMGYwOTNlZjYtYTJkZS00OGU2LTg3ZDQtMGZjN2UyMWI3NzU1Iiwicm9sZSI6IiJ9.Q7xS7JqpZAdtzkXBZxTAC3ZiUmTgvS1sd97bb-y_G6g";

	Connection* connection = new Connection("https://opendata.aemet.es/opendata/api/");
	connection->AppendHeader("api_key", api_key);
	connection->AppendHeader("Accept", "application/json");
	connection->AppendHeader("cache-control", "no-cache");
	Response r = connection->get("prediccion/especifica/municipio/diaria/18084");

	cout << "\nantes\n";
	cout << r.body;
	cout << "\ndespues\n";
*/
	return 0;
}

void imprimirListado(string c_prov) {
	Provincia p = (provincias.find(c_prov))->second;
	p.imprimirLocalidades();
}

void imprimirProvincias() {
	it_provincia = provincias.begin();

	for (it_provincia; it_provincia != provincias.end(); ++it_provincia) {
		cout << it_provincia->second.codigo << " - " << it_provincia->second.nombre << endl;
	}
}
