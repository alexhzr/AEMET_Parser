ALL: prediccion lex.yy.c 

prediccion: lex.yy.c
	g++ -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 lex.yy.c provincia.cc localidad.cc -I include/ -lfl -L /usr/local/lib/ -lrestclient-cpp -lcurl -o prediccion

lex.yy.c:
	flex prediccion.l

clean:
	rm lex.yy.c prediccion
