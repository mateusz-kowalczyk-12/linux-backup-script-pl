#!/bin/bash

### Obsługa opcji
##

# Funkcja wyświetla pomoc
function pomoc ()
{
   echo ""
   echo "------------------------------------------------------"
   echo "Program do wykonywania kopii zapasowej dysku w systemie operacyjnym z rodziny Linux (pomoc): "
   echo ""
   echo 'Program umożliwia tworzenie kopii zapasowej (opcja "1. Tworzenie kopii"):'
   echo '- dysku na innym dysku (opcja "Cały dysk")'
   echo '- partycji dysku na innej partycji lub dysku (opcja "Partycja dysku")'
   echo '- katalogu użytkownika (opcja "Dane użytkownika") w postaci skompresowanej lub nie'
   echo '- katalogów danych programów (opcja "Dane programów") w postaci skompresowanej lub nie'
   echo ""
   echo 'Możliwe jest także przywracanie tych danych (opcja "2. Przywracanie danych")'
   echo "Należy wówczas określić, czy dane będą przywracane z postaci skomopresowanej czy też nie"
   echo ""
   echo "Program wymaga uprawnień administratora ze względu na możliwość trwałego uszkodzenia dysku"
   echo '(przy jego uruchamnianiu poprzedź nazwę poleceniem "sudo")'
   echo "------------------------------------------------------"
   echo ""

    WYWOLANO_OPCJE=$(($WYWOLANO_OPCJE + 1))
}

# Funkcja wyświetla informację o autorze i wersji programu
function wersja ()
{
   echo ""
   echo "------------------------------------------------------"
   echo "Program do wykonywania kopii zapasowej dysku w systemie operacyjnym z rodziny Linux"
   echo ""
   echo "Autor: Mateusz Kowalczyk (s188717@student.pg.edu.pl)"
   echo "Wersja: 1.0"
   echo "------------------------------------------------------"
   echo ""

   WYWOLANO_OPCJE=$(($WYWOLANO_OPCJE + 1))
}

##
### Koniec obsługi opcji



### Niezależne funkcje kopiujące
##

# Funkcja wykonuje rekurencyjne kopiowanie katalogu
function kopiuj_katalog ()
{
   local ZAGLEBIENIE_CZYTANIA=$1
   local ZAGLEBIENIE_PISANIA=$2

   AKTUALNY_PLIK=$PLIK_KOPIOWANY$ZAGLEBIENIE_CZYTANIA

   if [[ -d $AKTUALNY_PLIK ]]
   then
      mkdir $LOKALIZACJA_ZAPISU$ZAGLEBIENIE_PISANIA
   
      for PLIK_Z_KATALOGU in `ls $AKTUALNY_PLIK`
      do
          kopiuj_katalog $ZAGLEBIENIE_CZYTANIA"/"$PLIK_Z_KATALOGU $ZAGLEBIENIE_PISANIA"/"$PLIK_Z_KATALOGU
      done
   else
      touch $LOKALIZACJA_ZAPISU$ZAGLEBIENIE_PISANIA

      #echo "Debug: wykonuję polecenie dd if=$PLIK_KOPIOWANY$ZAGLEBIENIE_CZYTANIA of=$LOKALIZACJA_ZAPISU$ZAGLEBIENIE_PISANIA status=none"
      dd if=$PLIK_KOPIOWANY$ZAGLEBIENIE_CZYTANIA of=$LOKALIZACJA_ZAPISU$ZAGLEBIENIE_PISANIA status=none
   fi
}


# Funkcja wykonuje proste kopiowanie
function kopiuj_urzadzenie ()
{
   #echo "Debug: wykonuję polecenie dd if=$PLIK_KOPIOWANY of=$LOKALIZACJA_ZAPISU status=none"
   dd if=$PLIK_KOPIOWANY of=$LOKALIZACJA_ZAPISU status=none
}

##
### Koniec niezależnych funckji kopiujących



### Wykonywanie kopii
##

# Funkcja przetwarza zgromadzone informacje i zarządza kopiowaniem katalogu
function kopiowanie_katalog ()
{
   zenity --info \
	        --title="Duży skrypt" \
	        --text="Po zakończeniu kopiowania pojawi się komunikat!" \
           --width=400

   NAZWA_PLIKU=${PLIK_KOPIOWANY##*/}

   kopiuj_katalog "" "/"$NAZWA_PLIKU

   if [[ $KOMPRESOWAC == 0 ]]
   then
      cd $LOKALIZACJA_ZAPISU
      tar -czf $NAZWA_PLIKU".tar.gz" $NAZWA_PLIKU
      rm -r $NAZWA_PLIKU
   fi

   zenity --info \
	        --title="Duży skrypt" \
	        --text="Kopia poprawnie wykonana" \
           --width=400
}


# Funkcja zarządza kopiowaniem urzadzenia
function kopiowanie_urzadzenie ()
{
   zenity --info \
	        --title="Duży skrypt" \
	        --text="Po zakończeniu kopiowania pojawi się komunikat!" \
           --width=400

   kopiuj_urzadzenie

   zenity --info \
	        --title="Duży skrypt" \
	        --text="Kopia poprawnie wykonana" \
           --width=400
}


# Funkcja zbiera informacje o sposobie zapisu
function dane_zapisu_urzadzenie ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "disk" |
   cut -d " " -f 1 > $NAZWY_PLIKOW
   lsblk |
   grep "part" |
   sed -e "s/└─//" |
   sed -e "s/├─//" |
   cut -d " " -f 1 >> $NAZWY_PLIKOW

   LOKALIZACJA_ZAPISU="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                  --title="Duży skrypt" \
                                  --text="Wybierz lokalizację zapisu" \
                                  --column="Urzadzenia" \
                                  --width=400 \
                                  --height=400`
    if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW
}


# Funkcja zbiera informacje o sposobie zapisu
function dane_zapisu_katalog ()
{
    
   zenity --question \
	       --title="Duży skrypt" \
	       --text="Czy kopia ma być skompresowana?" \
          --width=400
   KOMPRESOWAC=$?
    
   zenity --info \
	       --title="Duży skrypt" \
	       --text="Wybierz lokalizację zapisu" \
          --width=400
   if [[ $? == 1 ]]
   then
      exit 0
   fi
    
    LOKALIZACJA_ZAPISU=`zenity --file-selection \
    			                   --directory \
                               --title="Duży skrypt"`
   if [[ $? == 1 ]]
   then
      exit 0
   fi
}


# Funkcja kontroluje kopiowanie całego dysku
function kopia_calego_dysku ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "disk" |
   cut -d " " -f 1 > $NAZWY_PLIKOW

   PLIK_KOPIOWANY="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                                     --title="Duży skrypt" \
                                                     --text="Wybierz dysk" \
                                                     --column="Dyski" \
                                                     --width=400 \
                                                     --height=400`
    if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW

   dane_zapisu_urzadzenie
   kopiowanie_urzadzenie
}


# Funkcja kontroluje kopiowanie partycji dysku
function kopia_partycji_dysku ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "part" |
   cut -d " " -f 1 |
   sed -e "s/└─//" |
   sed -e "s/├─//" > $NAZWY_PLIKOW

   PLIK_KOPIOWANY="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                                     --title="Duży skrypt" \
                                                     --text="Wybierz partycję dysku" \
                                                     --column="Partycje dysku" \
                                                     --width=400 \
                                                     --height=400`
   if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW

   dane_zapisu_urzadzenie
   kopiowanie_urzadzenie
}


# Funkcja kontroluje kopiowanie danych programów
function kopia_danych_programow ()
{
   PLIK_KOPIOWANY=`zenity --list \
                          --title="Duży skrypt" \
                          --text="Wybierz katalog danych programów" \
                          --column="Katalogi danych programów" "/opt" "/usr/local" \
                          --width=400 \
                          --height=400`
   if [[ $? == 1 ]]
   then
      exit 0
   fi

   dane_zapisu_katalog
   kopiowanie_katalog
}


# Funkcja kontroluje kopiowanie danych użytkownika
function kopia_danych_uzytkownika ()
{
   PLIK_KOPIOWANY="/home/"`ls /home | zenity --list \
                                             --title="Duży skrypt" \
                                             --text="Wybierz użytkownika" \
                                             --column="Użytkownicy" \
                                             --width=400 \
                                             --height=400`
   if [[ $? == 1 ]]
   then
      exit 0
   fi

   dane_zapisu_katalog
   kopiowanie_katalog
}


# Funkcja-dyspozytor trybu wykonywania kopii
function tryb_wykonywania_kopii ()
{
   RODZAJ_PLIKU=`zenity --list \
   		               --title="Duży skrypt" \
  		                  --text="Wybierz rodzaj pliku do wykonania kopii zapasowej" \
  			               --column="Rodzaj pliku" "Cały dysk" "Partycja dysku" "Dane użytkownika" "Dane programów" \
                        --width=400 \
   			            --height=250`

   case $RODZAJ_PLIKU in
       "Cały dysk") kopia_calego_dysku;;
       "Partycja dysku") kopia_partycji_dysku;;
       "Dane użytkownika") kopia_danych_uzytkownika;;
       "Dane programów") kopia_danych_programow;;
   esac
}

##
### Koniec wykonywania kopii



### Przywracanie danych
##

# Funkcja zarządza przywracaniem urzadzenia
function przywracanie_urzadzenie ()
{
   zenity --info \
	        --title="Duży skrypt" \
	        --text="Po zakończeniu przywracania pojawi się komunikat!" \
           --width=400

   kopiuj_urzadzenie

   zenity --info \
	        --title="Duży skrypt" \
	        --text="Dane poprawnie przywrócone" \
           --width=400
}


# Funkcja zarządza przywracaniem katalogu
function przywracanie_katalog ()
{
   zenity --info \
	        --title="Duży skrypt" \
	        --text="Po zakończeniu przywracania pojawi się komunikat!" \
           --width=400

   NAZWA_PLIKU=`basename ${PLIK_KOPIOWANY%%.*}`
   RODZIC=`dirname $PLIK_KOPIOWANY`
   FOLDER_TYMCZASOWY=$RODZIC"/TEMP.$$"
   
   if [[ $ROZPAKOWYWAC == 0 ]]
   then
      # Rozpakowywanie do folderu tymczasowego

      mkdir $FOLDER_TYMCZASOWY

      cd $RODZIC
      tar -xf `basename $PLIK_KOPIOWANY` -C $FOLDER_TYMCZASOWY

      PLIK_KOPIOWANY=$FOLDER_TYMCZASOWY"/"$NAZWA_PLIKU

      ##
   fi
   
   rm -r $LOKALIZACJA_ZAPISU/*
   
   # Kopiowanie zawartlości przywracanego katalogu

   PLIK_KOPIOWANY_KOPIA=$PLIK_KOPIOWANY
   for PLIK_Z_KATALOGU in `ls $PLIK_KOPIOWANY`
   do
      PLIK_KOPIOWANY=$PLIK_KOPIOWANY_KOPIA"/"$PLIK_Z_KATALOGU
      kopiuj_katalog "" "/"$PLIK_Z_KATALOGU
   done

   ##

   if [[ -e $FOLDER_TYMCZASOWY ]]
   then
      rm -r $FOLDER_TYMCZASOWY
   fi

   zenity --info \
	        --title="Duży skrypt" \
	        --text="Dane poprawnie przywrócone" \
           --width=400
}


# Funkcja zbiera informacje o sposobie zapisu
function dane_przywracanego_urzadzenia ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "disk" |
   cut -d " " -f 1 > $NAZWY_PLIKOW
   lsblk |
   grep "part" |
   sed -e "s/└─//" |
   sed -e "s/├─//" |
   cut -d " " -f 1 >> $NAZWY_PLIKOW

   PLIK_KOPIOWANY="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                                     --title="Duży skrypt" \
                                                     --text="Wybierz urzadzenie z danymi" \
                                                     --column="Urzadzenia" \
                                                     --width=400 \
                                                     --height=400`
    if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW
}


# Funkcja zbiera informacje o sposobie zapisu
function dane_przywracanego_katalogu ()
{
   # Potrzebne do ustalenia, czy ustawiać opcję --directory w zenity

   zenity --question \
	       --title="Duży skrypt" \
	       --text="Czy katalog z danymi jest skompresowany?" \
          --width=400
   ROZPAKOWYWAC=$?

   ##
    
   zenity --info \
	       --title="Duży skrypt" \
	       --text="Wybierz katalog z danymi" \
          --width=400
   if [[ $? == 1 ]]
   then
      exit 0
   fi
   
   if [[ $ROZPAKOWYWAC == 1 ]]
   then
      PLIK_KOPIOWANY=`zenity --file-selection \
    			                 --directory \
                             --title="Duży skrypt"`
      if [[ $? == 1 ]]
      then
         exit 0
      fi
   else
      PLIK_KOPIOWANY=`zenity --file-selection \
                             --title="Duży skrypt"`
      if [[ $? == 1 ]]
      then
         exit 0
      fi
   fi
}


# Funkcja kontroluje przywracanie całego dysku
function przywracanie_calego_dysku ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "disk" |
   cut -d " " -f 1 > $NAZWY_PLIKOW

   LOKALIZACJA_ZAPISU="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                                         --title="Duży skrypt" \
                                                         --text="Wybierz dysk, na którym chcesz przywrócić dane" \
                                                         --column="Dyski" \
                                                         --width=400 \
                                                         --height=400`
    if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW

   dane_przywracanego_urzadzenia
   przywracanie_urzadzenie
}


# Funkcja kontroluje przywracanie partycji dysku
function przywracanie_partycji_dysku ()
{
   NAZWY_PLIKOW=$(mktemp)

   lsblk |
   grep "part" |
   cut -d " " -f 1 |
   sed -e "s/└─//" |
   sed -e "s/├─//" > $NAZWY_PLIKOW

   LOKALIZACJA_ZAPISU="/dev/"`cat $NAZWY_PLIKOW | zenity --list \
                                                         --title="Duży skrypt" \
                                                         --text="Wybierz partycję dysku, na którą chcesz przywrócic dane" \
                                                         --column="Partycje dysku" \
                                                         --width=400 \
                                                         --height=400`
   if [[ $? == 1 ]]
    then
      rm $NAZWY_PLIKOW
      exit 0
   fi
   rm $NAZWY_PLIKOW

   dane_przywracanego_urzadzenia
   przywracanie_urzadzenie
}


# Funkcja kontroluje przywracanie danych użytkownika
function przywracanie_danych_uzytkownika ()
{
   LOKALIZACJA_ZAPISU="/home/"`ls /home | zenity --list \
                                                 --title="Duży skrypt" \
                                                 --text="Wybierz użytkownika, do którego chcesz przywrócić dane" \
                                                 --column="Użytkownicy" \
                                                 --width=400 \
                                                 --height=400`
   if [[ $? == 1 ]]
   then
      exit 0
   fi
   
   dane_przywracanego_katalogu
   przywracanie_katalog
}


# Funkcja kontroluje przywracanie danych programów
function przywracanie_danych_programow ()
{
   LOKALIZACJA_ZAPISU=`zenity --list \
                              --title="Duży skrypt" \
                              --text="Wybierz katalog danych programów, do którego chcesz przywrócić dane" \
                              --column="Katalogi danych programów" "/opt" "/usr/local" \
                              --width=400 \
                              --height=400`
   if [[ $? == 1 ]]
   then
      exit 0
   fi

   dane_przywracanego_katalogu
   przywracanie_katalog
}


# Funkcja-dyspozytor trybu przywracania danych
function tryb_przywracania_danych ()
{
   RODZAJ_PLIKU=`zenity --list \
   		               --title="Duży skrypt" \
  		                  --text="Wybierz rodzaj pliku do przywrócenia" \
  			               --column="Rodzaj pliku" "Cały dysk" "Partycja dysku" "Dane użytkownika" "Dane programów" \
                        --width=400 \
   			            --height=250`

   case $RODZAJ_PLIKU in
       "Cały dysk") przywracanie_calego_dysku;;
       "Partycja dysku") przywracanie_partycji_dysku;;
       "Dane użytkownika") przywracanie_danych_uzytkownika;;
       "Dane programów") przywracanie_danych_programow;;
   esac
}

##
### Koniec przywracanie danych



### Przetwarzanie opcji podanych przy wywołaniu skryptu
##

WYWOLANO_OPCJE=0

while getopts 'h''v' OPT
do
   case $OPT in
      'h') pomoc;;
      'v') wersja;;
   esac
done

if [[ $WYWOLANO_OPCJE > 0 ]]
then
   exit
fi

##
### Koniec przetwarzania opcji podanych przy wywołaniu skryptu


### Menu główne
##

TRYB=`zenity --list \
             --title="Duży skrypt" \
             --text="Witaj w programie do wykonywania kopii zapasowej dysku\nw systemie operacyjnym z rodziny Linux!\nWybierz tryb z menu." \
             --column="Menu" "1. Wykonywanie kopii" "2. Przywracanie danych" \
             --cancel-label="Wyjdź" \
             --width=400 \
             --height=225`

case $TRYB in
   "1. Wykonywanie kopii") tryb_wykonywania_kopii;;
   "2. Przywracanie danych") tryb_przywracania_danych;;
esac

##
### Koniec menu głównego
