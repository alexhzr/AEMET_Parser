/** 
 *  @file    prediccion.l
 *  @author  Alejandro Hernández (alexhzr)
 *	@author  Miguel Toledo (miguel_toledo)
 *  @date    30/11/17  
 *  @version 1.0 
 *  
 *  @brief Proyecto en Lex para Modelos de Computación - Universidad de Granada
 */

%{

#include <stdio.h>
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include <iterator>

#include "localidad.h"
#include "provincia.h"

using namespace std;

struct datos_viento {
	string direccion;
	int velocidad;
};

struct datos_temp_humedad_sensacion {
	int maxima, minima;
	map<string, int> valor_por_horas;
};

//Variables para la primera parte del programa (parseado de ficheros de localidades y provincias)
map<string, Provincia> provincias;
string nombre_provincia, nombre_localidad, codigo_provincia, codigo_localidad;
map<string, Provincia>::iterator it_provincia;
pair<map<string, Provincia>::iterator,bool> ret;

//Variables para la segunda parte del programa (parseado del fichero prevision.json)
map<string, string> desc_estados_cielo;
map<string, int> prob_precipitacion, estados_cielo;
map<string, datos_viento> viento;
datos_temp_humedad_sensacion temperaturas, sensaciones, humedades;
int indice_uv;

int horas = 1;
datos_viento temp_datosviento;
string fecha, tmp_valor, tmp_valor2;
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
%s N_PUEBLO_PREDICCION
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

cualquier_nombre [^ \n<>".:]*
numero [0-9]
id_localidad {numero}{3}
id_provincia [0-5]{2}
label_nombre_localidad nombre_loc
label_id_localidad cmun
label_id_provincia cprov
label_nombre_provincia nombre_prov
fin_archivo fin_archivo

label_nombre nombre
label_prob_precipitacion probPrecipitacion
label_fecha fecha
label_estado_cielo estadoCielo
label_viento viento
label_temperatura temperatura
fecha ([12]{numero}{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]{numero}|3[01]))
periodo {numero}{2}-{numero}{2}
valor {numero}+
direccion_viento C|N|NE|NO|S|SE|SO|E|O
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


nombre { BEGIN(N_PUEBLO_PREDICCION); }
<N_PUEBLO_PREDICCION>{cualquier_nombre} { nombre_localidad = yytext; cout << nombre_localidad << endl; BEGIN(FICHERO_PREDICCION); }

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
			temp_datosviento.direccion = tmp_valor2;
			temp_datosviento.velocidad = stoi(tmp_valor);

			viento.insert(make_pair(yytext, temp_datosviento));
			cout << "periodo: " << viento.find(yytext)->first << " | direccion: " << viento.find(yytext)->second.direccion << " | velocidad: " << viento.find(yytext)->second.velocidad << endl; 
		}

	} else if (leyendo_precip) {
			if (strcmp(yytext, "00-24") == 0 ||
				strcmp(yytext, "00-06") == 0 ||
				strcmp(yytext, "06-12") == 0 ||
				strcmp(yytext, "12-18") == 0 ||
				strcmp(yytext, "18-24") == 0) {
					prob_precipitacion.insert(make_pair(yytext, stoi(tmp_valor)));
					cout << "periodo: " << prob_precipitacion.find(yytext)->first << " | valor: " << prob_precipitacion.find(yytext)->second << endl; 
				}
	} else if (leyendo_cielo) {
		if ((strcmp(yytext, "00-06") == 0) ||
			(strcmp(yytext, "06-12") == 0) ||
			(strcmp(yytext, "12-18") == 0) ||
			(strcmp(yytext, "18-24") == 0)) {
				estados_cielo.insert(make_pair(yytext, stoi(tmp_valor)));
				cout << "periodo: " << estados_cielo.find(yytext)->first << " | valor: " << estados_cielo.find(yytext)->second << endl;
			}

	} 
}

{label_estado_cielo}							{ cout << "# " << yytext << " -> " << endl; BEGIN(ESTADO_CIELO); }
<ESTADO_CIELO>{empezar_array}					{ leyendo_cielo = true; BEGIN(LEYENDO_ARRAY); }

<LEYENDO_ARRAY>{valor}							{ tmp_valor = yytext; }

{label_viento}									{ cout << "# " << yytext << " -> " << endl; leyendo_viento = true; BEGIN(VIENTO); }
<VIENTO>{empezar_array}							{ BEGIN(LEYENDO_ARRAY); }
<LEYENDO_ARRAY>{direccion_viento}				{ tmp_valor2 = yytext; }

{label_temperatura}								{ leyendo_temp = true; leyendo_humedad = leyendo_sens = false; cout << "# " << yytext << " -> "; BEGIN(TEMP_Y_SENS); }

<TEMP_Y_SENS>{label_maxima}						{ cout << yytext << ": "; BEGIN(TEMP_MAXIMA); }
<TEMP_Y_SENS>{label_minima}  					{ cout << yytext << ": "; BEGIN(TEMP_MINIMA); }

<TEMP_MAXIMA>{valor} { 
	if (leyendo_temp) {
		temperaturas.maxima = stoi(yytext);
		cout << temperaturas.maxima << ", ";	
	} else if (leyendo_sens) {
		sensaciones.maxima = stoi(yytext);
		cout << sensaciones.maxima << ", ";
	} else if (leyendo_humedad) {
		humedades.maxima = stoi(yytext);
		cout << humedades.maxima << ", ";
	}	

	 BEGIN(TEMP_Y_SENS); 
}
<TEMP_MINIMA>{valor} { 
	if (leyendo_temp) {
		temperaturas.minima = stoi(yytext);
		cout << temperaturas.minima << ", " << endl;	
	} else if (leyendo_sens) {
		sensaciones.minima = stoi(yytext);
		cout << sensaciones.minima << ", " << endl;
	} else if (leyendo_humedad) {
		humedades.minima = stoi(yytext);
		cout << humedades.minima << ", " << endl;
	}

	BEGIN(TEMP_XH); 
}

<TEMP_XH>{valor}	{ tmp_valor = yytext; BEGIN(HORA); }
<HORA>{valor} { 
	if (horas <= 4) {
		if (leyendo_temp) {
			temperaturas.valor_por_horas.insert(make_pair(yytext, stoi(tmp_valor)));
			cout << "a las " << temperaturas.valor_por_horas.find(yytext)->first << "h hacen " << temperaturas.valor_por_horas.find(yytext)->second << "ºC" << endl;
		} else if (leyendo_sens) {
			sensaciones.valor_por_horas.insert(make_pair(yytext, stoi(tmp_valor)));
			cout << "a las " << sensaciones.valor_por_horas.find(yytext)->first << "h hacen " << sensaciones.valor_por_horas.find(yytext)->second << "ºC" << endl;

		} else if (leyendo_humedad) {
			humedades.valor_por_horas.insert(make_pair(yytext, stoi(tmp_valor)));
			cout << "a las " << humedades.valor_por_horas.find(yytext)->first << "h la humedad será del " << humedades.valor_por_horas.find(yytext)->second << "%" << endl;
		}

		horas++;
		BEGIN(TEMP_XH);
	} else
		BEGIN(INITIAL);

}

{label_sens_termica}			{ leyendo_sens = true; leyendo_temp = leyendo_humedad = false; cout << endl << "# " << yytext << " -> "; horas = 1; BEGIN(TEMP_Y_SENS); }
{label_humedad}	{ leyendo_humedad = true; leyendo_sens = leyendo_temp = false; cout << endl << "# " << yytext << " -> "; horas = 1; BEGIN(TEMP_Y_SENS);}
{fecha}	{ fecha = yytext; }


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
	desc_estados_cielo.insert(make_pair("11", "Despejado"));
	desc_estados_cielo.insert(make_pair("12", "Poco Nubloso"));
	desc_estados_cielo.insert(make_pair("13", "Intervalos Nublosos"));
	desc_estados_cielo.insert(make_pair("14", "Nubloso"));
	desc_estados_cielo.insert(make_pair("15", "Muy Nubloso"));
	desc_estados_cielo.insert(make_pair("16", "Cubierto"));
	desc_estados_cielo.insert(make_pair("17", "Nubes Altas"));
	desc_estados_cielo.insert(make_pair("18", "Intervalos nublosos con lluvia"));
	desc_estados_cielo.insert(make_pair("19", "Nubloso con lluvia"));
	desc_estados_cielo.insert(make_pair("20", "Muy nubloso con lluvia"));
	desc_estados_cielo.insert(make_pair("21", "Cubierto con lluvia"));
	desc_estados_cielo.insert(make_pair("22", "Intervalos nublosos con nieve"));
	desc_estados_cielo.insert(make_pair("23", "Nubloso con nieve"));
	desc_estados_cielo.insert(make_pair("24", "Muy nubloso con nieve"));
	desc_estados_cielo.insert(make_pair("25", "Chubascos"));
	desc_estados_cielo.insert(make_pair("26", "Tormenta"));
	desc_estados_cielo.insert(make_pair("27", "Granizo"));
	desc_estados_cielo.insert(make_pair("28", "Bruma"));
	desc_estados_cielo.insert(make_pair("29", "Niebla"));
	desc_estados_cielo.insert(make_pair("30", "Calma"));
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
