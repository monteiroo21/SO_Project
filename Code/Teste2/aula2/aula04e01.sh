#!/bin/bash

function imprime_msg(){
	echo "A minha primeira função"
	return 0
}


function info_adicional() {
	echo -n "Data de hoje: "
	date
	echo -n "Nome do PC: "
        hostname
	echo -n "Nome do utilizador: "
	whoami	
}	


