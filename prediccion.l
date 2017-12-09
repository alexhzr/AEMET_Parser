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

using namespace std;

map<string, Provincia> provincias;
string nombre_provincia, nombre_localidad, codigo_provincia, codigo_localidad;
map<string, Provincia>::iterator it_provincia;
pair<map<string, Provincia>::iterator,bool> ret;
int horas = 1;

map<string, string> estados_cielo;
string fecha, prob_precipitacion, tmp_valor, tmp_valor2;
bool leyendo_viento, leyendo_precip, leyendo_temp, leyendo_sens, leyendo_cielo, leyendo_humedad;

void inicializar();
void imprimirListado(string c_prov);
void imprimirProvincias();
%}

%s NOMBRE_LOCALIDAD
%s NOMBRE_PROVINCIA
%s ID_PROVINCIA 
%s ID_LOCALIDAD
%s LEYENDO_LOCALIDADES

%s FICHERO_PREDICCION
%s XXDIAXX
%s DIA
%s FECHA
%s LEYENDO_ARRAY
%s LEYENDO_ARRAY_VIENTO
%s LEYENDO_ARRAY_TEMPERATURA
%s LEYENDO_ARRAY_CIELO
%s PROB_PRECIPITACION
%s ESTADO_CIELO
%s VIENTO
%s TEMP_Y_SENS
%s TEMP_MINIMA
%s TEMP_MAXIMA
%s TEMP_XH
%s HORA
%s SENS_TERMICA

empezar_array "["
acabar_array "]"

cualquier_nombre [^ \n<>.:]*
numero [0-9]
id_localidad {numero}{3}
id_provincia [0-5]{2}
label_nombre_localidad nombre_loc
label_id_localidad cmun
label_id_provincia cprov
label_nombre_provincia nombre_prov
fin_archivo fin_archivo

label_prob_precipitacion probPrecipitacion
label_fecha "fecha"
label_estado_cielo estadoCielo
label_viento viento
label_temperatura temperatura
fecha ([12]{numero}{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]{numero}|3[01]))
periodo {numero}{2}-{numero}{2}
valor {numero}+
direccion_viento [C|N|NE|NO|S|SE|SO|E|O]
label_maxima maxima
label_minima minima
label_hora hora
label_sens_termica sensTermica
label_humedad humedadRelativa



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

<LEYENDO_LOCALIDADES>{acabar_array}				{ BEGIN(INITIAL); }
{fin_archivo}									{ cout << "encontrado fin archivo\n"; BEGIN(INITIAL); }



<INITIAL,FICHERO_PREDICCION>{empezar_array}		{ BEGIN(XXDIAXX); }

<XXDIAXX>"{"									{ BEGIN(DIA); }
<DIA>{label_prob_precipitacion}					{ cout << "# " << yytext << " -> " << endl; leyendo_precip = true; BEGIN(PROB_PRECIPITACION); }

<PROB_PRECIPITACION>{empezar_array}				{ BEGIN(LEYENDO_ARRAY); }
<LEYENDO_ARRAY,LEYENDO_ARRAY_TEMPERATURA,TEMP_Y_SENS>{acabar_array}					{ 
	cout << "\nacabo array\n";
	leyendo_precip = leyendo_viento = leyendo_humedad = leyendo_cielo = leyendo_sens = leyendo_temp = false;
	BEGIN(INITIAL); 
}

<LEYENDO_ARRAY>{periodo}|hora	{ 	

	if (leyendo_viento) {
		if (strcmp(yytext, "00-24") == 0 ||
			strcmp(yytext, "00-06") == 0 ||
			strcmp(yytext, "06-12") == 0 ||
			strcmp(yytext, "12-18") == 0 ||
			strcmp(yytext, "18-24") == 0) { 
			cout << "periodo: " << yytext << " | direccion: " << tmp_valor2 << " | velocidad: " << tmp_valor << endl; 
		}

	} else if (leyendo_precip) {
			if (strcmp(yytext, "00-24") == 0 ||
				strcmp(yytext, "00-06") == 0 ||
				strcmp(yytext, "06-12") == 0 ||
				strcmp(yytext, "12-18") == 0 ||
				strcmp(yytext, "18-24") == 0) {
					cout << "periodo: " << yytext << " | valor: " << tmp_valor << endl; 
				}
	} else if (leyendo_cielo) {
		if ((strcmp(yytext, "00-06") == 0) ||
			(strcmp(yytext, "06-12") == 0) ||
			(strcmp(yytext, "12-18") == 0) ||
			(strcmp(yytext, "18-24") == 0)) 
				cout << "periodo: " << yytext << " | valor: " << tmp_valor << endl;

	} else if (leyendo_sens) {
		cout << "a las " << yytext << " la sensación es de ";
	} else {
		if (strcmp(yytext, "00-24") == 0) { 
			cout << "periodo: " << yytext << " | valor: " << tmp_valor << endl; 
		}
	}
}

{label_estado_cielo}							{ cout << "# " << yytext << " -> " << endl; BEGIN(ESTADO_CIELO); }
<ESTADO_CIELO>{empezar_array}					{ leyendo_cielo = true; BEGIN(LEYENDO_ARRAY); }

<LEYENDO_ARRAY>{valor}							{ tmp_valor = yytext; }

{label_viento}									{ cout << "# " << yytext << " -> " << endl; leyendo_viento = true; BEGIN(VIENTO); }
<VIENTO>{empezar_array}							{ BEGIN(LEYENDO_ARRAY); }
<LEYENDO_ARRAY>{direccion_viento}				{ tmp_valor2 = yytext; }

{label_temperatura}								{ cout << "# " << yytext << " -> "; BEGIN(TEMP_Y_SENS); }

<TEMP_Y_SENS>{label_maxima}						{ cout << yytext << ": "; BEGIN(TEMP_MAXIMA); }
<TEMP_Y_SENS>{label_minima}  					{ cout << yytext << ": "; BEGIN(TEMP_MINIMA); }
<TEMP_MAXIMA>{valor}							{ cout << yytext << ", "; BEGIN(TEMP_Y_SENS); }
<TEMP_MINIMA>{valor}							{ cout << yytext << endl; BEGIN(TEMP_XH); }
<TEMP_XH>{valor}								{ tmp_valor = yytext; BEGIN(HORA); }
<HORA>{valor}									{ 
													if (horas <= 4) { 
														cout << "a las " << yytext << "h hacen " << tmp_valor << "ºC" << endl; 
														horas++;
														BEGIN(TEMP_XH); 
													} else 
														BEGIN(INITIAL);
												}

{label_sens_termica}|{label_humedad}			{ cout << endl << "# " << yytext << " -> "; horas = 1; BEGIN(TEMP_Y_SENS); }



.	{}
\n 	{}

%%



int main(int argc, char *argv[]) {
	cout << "Parseando fichero localidades..." << endl;;
	yyin = fopen("localidades_prueba.json", "rt");
	if (yyin == NULL) {
		printf("El fichero %s no se puede abrir\n", argv[1]);
		exit(-1);
	}

	yylex();

	string prov_selecc;
	int c_prov;

	/*do {
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
	} while (false);*/

	//===========================================================
	//				PARSEAR FICHERO PREDICCIÓN
	//===========================================================

	cout << "Parseando fichero predicción..." << endl;;
	yyin = fopen("prevision_granada.json", "rt");
	if (yyin == NULL) {
		printf("El fichero %s no se puede abrir\n", argv[1]);
		exit(-1);
	}

	yylex();

	/*const string base_url = "https://opendata.aemet.es/opendata/api/";
	const string api_key = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGVqYW5kcm9oZXJuYW5kZXpyZWNpb0BnbWFpbC5jb20iLCJqdGkiOiIwZjA5M2VmNi1hMmRlLTQ4ZTYtODdkNC0wZmM3ZTIxYjc3NTUiLCJpc3MiOiJBRU1FVCIsImlhdCI6MTUwOTk4MjU4NCwidXNlcklkIjoiMGYwOTNlZjYtYTJkZS00OGU2LTg3ZDQtMGZjN2UyMWI3NzU1Iiwicm9sZSI6IiJ9.Q7xS7JqpZAdtzkXBZxTAC3ZiUmTgvS1sd97bb-y_G6g";
	string granada = "18007";

	RestClient::Connection *connection = new RestClient::Connection("https://opendata.aemet.es/opendata/api/");
	connection->AppendHeader("api_key", api_key);
	connection->AppendHeader("Accept", "application/json");
	connection->AppendHeader("cache-control", "no-cache");
	RestClient::Response r = connection->get("prediccion/especifica/municipio/diaria/18084");

	cout << "\nantes\n";
	cout << r.body;
	cout << "\ndespues\n";*/

	return 0;
}

void inicializar() {
	estados_cielo.insert(make_pair("11", "Despejado"));
	estados_cielo.insert(make_pair("12", "Poco Nubloso"));
	estados_cielo.insert(make_pair("13", "Intervalos Nublosos"));
	estados_cielo.insert(make_pair("14", "Nubloso"));
	estados_cielo.insert(make_pair("15", "Muy Nubloso"));
	estados_cielo.insert(make_pair("16", "Cubierto"));
	estados_cielo.insert(make_pair("17", "Nubes Altas"));
	estados_cielo.insert(make_pair("18", "Intervalos nublosos con lluvia"));
	estados_cielo.insert(make_pair("19", "Nubloso con lluvia"));
	estados_cielo.insert(make_pair("20", "Muy nubloso con lluvia"));
	estados_cielo.insert(make_pair("21", "Cubierto con lluvia"));
	estados_cielo.insert(make_pair("22", "Intervalos nublosos con nieve"));
	estados_cielo.insert(make_pair("23", "Nubloso con nieve"));
	estados_cielo.insert(make_pair("24", "Muy nubloso con nieve"));
	estados_cielo.insert(make_pair("25", "Chubascos"));
	estados_cielo.insert(make_pair("26", "Tormenta"));
	estados_cielo.insert(make_pair("27", "Granizo"));
	estados_cielo.insert(make_pair("28", "Bruma"));
	estados_cielo.insert(make_pair("29", "Niebla"));
	estados_cielo.insert(make_pair("30", "Calma"));
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
