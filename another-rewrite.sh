#!/bin/bash


#=-----=# CONFIG #=-----=#

input=
output=
codec=()

rename=(n) # {y|n|photos|videos|audio}
crop=(n) # {y|n|photos|video} {}

overwrite=
recursive=
verbose=
logging=
threads=
crf=

include=() # {all|photos|videos|audio}
exclude=() # {photos|videos|audio}

musicBitrate='128'
audioBitrate='64'

av1Quality='2'
vp9Quality='-5'
avifQuality='0'

avifMaxQuality='63'
avifMinQuality='0'

maxSize='1280'
doMaxSize='y'

#=-=# END OF CONFIG #=-=#


# help menu
usage() {

  echo "USAGE : $0 <input> <output> [arguments] "
  echo
  echo "Input options :"
  echo
  echo "  -i, --include {videos|photos|audio}"
  echo "  -e, --exclude {videos|photos|audio}"
  echo "      > Include or exclude file types"
  echo
  echo "  -r, --recursive"
  echo "      > Include subfolders"
  echo "  -o, --overwrite"
  echo "      > Overwrites already compressed files"
  echo "  -t, --threads <all|number-of-threads>"
  echo "      > Number of threads to use"
  echo
  echo "Output options :"
  echo
  echo "  -C, --codec {jpg|jxl|avif|h264|h265|vp9|av1|vvc|mp3|opus} {quality}"
  echo "      > Choose encoding codecs and quality parameters"
  echo "      > Quality arguments : (values are sorted from best to worse)"
  echo "        • jpg <q:scale> (2-31) <preset> (placebo-veryfast)"
  echo "        • jxl"
  echo "        • avif <min> (0-63) <max> (0-63) <speed> (0-10)"
  echo "        • h264|h265 <crf> (0-63) <preset> (placebo-veryfast) <opus-bitrate> (256-6)"
  echo "        • vp9 <crf> (0-63) <cpu-used> (-8 - 8) <opus-bitrate> (256-6)"
  echo "        • av1 <cq-level> (0-8) <cpu-used> (0-9) <opus-bitrate> (256-6)"
  echo "        • vvc"
  echo "        • mp3|opus <bitrate>"
  echo "      > Example : -C vp9 21 -5 avif 30 mp3 192 opus"
  echo "  -c, --crop {all|photos|videos} <width>x<height>"
  echo "      > Crop and zoom to fit whithout distortions"
  echo "  -m, --max-size {all|photos|videos} <pixels>"
  echo "      > Set a maximum lenght size in pixels"
  echo "  -R, --rename {all|photos|videos|audio}"
  echo "      > Rename the output files to their timestamps"
  echo
  echo "Other"
  echo
  echo "  -v, --verbose : print more information"
  echo "  -l, --log {file} : --verbose redirected to a file"
  echo "  -h, --help : print this menu"
  echo
  exit

}

# argument processing
echo
args=($*); [[ -z "${args[0]}" ]] && usage
for ((i=0; i < "${#args[@]}"; i++)); do

  case "${args[i]}" in
    '--codec'|'-c') ((i++))
      echo "deal : ${args[i]}"

      while [[ "${args[i]:0:1}" != '-' && "${args[i]}" != '' ]]; do
        case "${args[i]}" in
          'vp9'|'av1') [[ -z "$videoCodec" ]] && videoCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one video codec\e[0m";;
          'jpg'|'avif') [[ -z "$imageCodec" ]] && imageCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one image codec\e[0m";;
          'mp3'|'opus') [[ -z "$audioCodec" ]] && audioCodec="${args[i]}" || \
            echo -e "\e[31mERROR : Please input only one audio codec\e[0m";;
          *) echo -e "\e[31mERROR : Bad codec\e[0m"; echo; usage;;
        esac
        ((i++))
      done
      ((i--));;

    '--recursive'|'-r') recursivity='true';;
    '--verbose'|'-v') verbose='true';;
    '--help'|'-h') usage;;

    -*)echo -e "\e[31mERROR : Invalid argument : '${args[i]}'\e[0m"
       [[ "${args[i]:0:1}" != '-' ]] && ((i++)); echo; usage;;

    *) if [[ -z "$input" ]]; then
         input="$(readlink -f ${args[i]})"
         if [[ ! -d "$input" && ! -f "$input" ]]; then
           echo -e "\e[31mERROR : Input path isn't a file or directory : '$input'\e[0m" && echo && exit
         fi
       elif [[ -z "$output" ]]; then
         output="$(readlink -f ${args[i]})"
         if [[ ! -d "$output" ]]; then
           echo -e "\e[31mERROR : Output path isn't a directory : '${output}'\e[0m\n"
           read -ren1 -p "Do you want to create it ? (default=n) : " makeOutputDirectory
           echo
           [[ "$makeOutputDirectory" = 'y' ]] && mkdir -p "$output" || unset output
         fi
       fi;;

  esac

done

[[ -z "$input" ]] && echo -e "\e[31mERROR : Input and output paths aren't set\e[0m\n" && exit
[[ -z "$output" ]] && echo -e "\e[31mERROR : Output path isn't set\e[0m\n" && exit

# verbose information
if [[ "$verbose" == 'true' ]]; then
  [[ -z "$input" ]] && input='not set'
  [[ -z "$output" ]] && output='not set'
  [[ -z "$recursivity" ]] && recursivity='false'
  [[ -z "$videoCodec" ]] && videoCodec='av1'
  [[ -z "$imageCodec" ]] && imageCodec='avif'
  [[ -z "$audioCodec" ]] && audioCodec='opus'
  echo -en '\e[36m'
  echo 'DEBBUGGING :'
  echo
  echo "Input : $input"
  echo "Output : $output"
  echo "Recursivity : $recursivity"
  echo "Video codec : $videoCodec"
  echo "Image codec : $imageCodec"
  echo "Audio codec : $audioCodec"
  echo -e '\e[0m'
fi

echo 'Starting...'
echo
