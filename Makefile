ALL: prediccion lex.yy.c 

prediccion: lex.yy.c
	g++ -D_GLIBCXX_USE_CXX11_ABI=0 lex.yy.c provincia.cc localidad.cc -Iinclude/ -lfl -L/usr/local/lib/ -lrestclient-cpp -o prediccion

lex.yy.c:
	flex prediccion.l

clean:
	rm lex.yy.c prediccion
