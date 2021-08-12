#!/bin/bash

# Skrypt do nauki skrótów angielskich na SOper

plik='skroty.txt' # domyślny

if [[ $1 == "--help" ]]
then
	echo "Skrypt do nauki skrótów na przedmiot systemy operacyjne."
	printf "  %-9s %s\n" "-f [file]" "Wykorzystuje inny plik z pytaniami."
	printf "  %-9s %s\n" "" "Plik domyślny: $plik."
	printf "  %-9s %s\n" "" "Kolejne linie pliku powinny mieć postać SKRÓT:ang:pol"
	printf "  %-9s %s\n" "-p" "Wyświetla wszystkie skróty wraz z ich rozwinięciami."	
	printf "  %-9s %s\n" "-s" "Wyłącza domyślne sortowanie skrótów."

	exit
fi

opcja_wyswietl=false
sortowanie=true

while getopts "psf:" opcja
do
	case $opcja in
		p) # print
			opcja_wyswietl=true
		;;
		f) # file
			plik="$OPTARG"
		;;
		s) # disable sorting
			sortowanie=false
		;;
	esac
done

max_punkty=0
declare -A skroty_ang # angielskie rozwinięcie
declare -A skroty_pol # polskie tłumaczenie

# Wczytywanie pliku postaci
#SKRÓT:ang:pol
#SKRÓT:ang:pol

internal_field_separator=$IFS # zapamiętanie żeby później przywrócić
IFS=':'
while read skrot ang pol komentarz
do
	if ! [ -z "$skrot" ]
	then
		let max_punkty++
		skroty_ang[$skrot]="$ang"
		skroty_pol[$skrot]="$pol"
	fi
done < <(cat "$plik")

IFS=$internal_field_separator # przywrócenie IFS (bo ma wpływ np. na for !!)

if (($max_punkty == 0))
then
	echo "Brak skrótów. Zobacz: $0 --help"
	exit 1
fi

# sortowanie
if $sortowanie
then
	klucze=$(
	for klucz in ${!skroty_ang[@]}
	do
		echo "$klucz"
	done | sort
	)
else
	klucze=${!skroty_ang[@]}
fi


if $opcja_wyswietl
then
	for skr in $klucze
	do
		printf "%-6s %s\n       %s\n" "$skr" "${skroty_ang[$skr]}" "${skroty_pol[$skr]}"
	done
else # właściwa część - pytania
	echo "Wpisz ':EXIT', aby zakończyć."
	punkty_ang=0
	punkty_pol=0
	for skr in $klucze
	do

		## angielski skrót ##
		echo
		echo "Podaj angielskie rozwinięcie skrótu $skr."
		echo -n 'Odpowiedź: '
		read odp

		if [[ "${odp^^}" == ":EXIT" ]]
		then
			break
		elif [[ "${odp,,}" == "${skroty_ang[$skr],,}" ]]
		then
			let punkty_ang++
			echo "OK!"

		else
			echo "Poprawnie: ${skroty_ang[$skr]}"
			echo "$skr:${skroty_ang[$skr]}:${skroty_pol[$skr]}" >> "niepopr_${plik}"
		fi


		## polskie tłumaczenie ##
		echo
		echo "Podaj polskie rozwinięcie skrótu $skr."
		echo -n 'Odpowiedź: '
		read odp

		if [[ "${odp^^}" == ":EXIT" ]]
		then
			break
		elif [[ "${odp,,}" == "${skroty_pol[$skr],,}" ]]
		then
			let punkty_pol++
			echo "OK!"

		else
			echo "Poprawnie: ${skroty_pol[$skr]}"
			echo "$skr:${skroty_ang[$skr]}:${skroty_pol[$skr]}" >> "niepopr_${plik}"
		fi


	done

	echo
	echo "Zdobyte punkty (angielski): $punkty_ang/$max_punkty ($( echo " $punkty_ang * 100 / $max_punkty" | bc )%)"
	echo "Zdobyte punkty (polski): $punkty_pol/$max_punkty ($( echo " $punkty_pol * 100 / $max_punkty" | bc )%)"
	echo
	echo "Skróty, na które zostały udzielone błędne odpowiedzi zostały zapisane w pliku niepopr_${plik}"
fi



