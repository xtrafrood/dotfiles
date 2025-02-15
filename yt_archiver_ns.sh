

### This script requires the following software
### yt-dlp: https://github.com/yt-dlp/yt-dlp#installation
### imagemagick
### libnotify4 (arch: libnotify)
### ffmpeg (merges thumbnail, subtitles, and m4a audio to final video file--up to 1080p 60fps)
### Jellyfin for local network streaming

## This script downloads specified YouTube video, and applies creator thumbnail,
## and auto generated or creator made subtitles to metadata
## Example command: ./script.sh "super-neat-yt-video-url.com"
## All files download to: $ytviddir
## Generating a cookies.txt file can be done with Firefox extension: Cookies.txt
## I use alias ytd: alias ytd="/home/$HOME/.scripts/yt_archiver.sh" via .bashrc

##### Using this in a way that hammers Google servers (10 calls/second+)
##### may distrupt your access to the YouTube api and or YouTube.

### Tested fine for English subtitles (more or less--could be hot mess)
### Might need work for other languages, and it might fail on fresh
### videos (YT takes a few minutes to auto generate subtitles 30-60min)

## The variables
ytdurl="$1"
ytfn="$(yt-dlp $ytdurl -o "%(title)s" --get-filename)"
ytviddir="$HOME/Videos/YouTube"
cookiez="$HOME/cookies.txt"
ytm4a="${RANDOM}.m4a"
ytthumb="${RANDOM}"

cd $ytviddir

## Audio Language check (140,140-0,140-14,140-drc= English)
if [[ "$(yt-dlp --list-formats "$1" | grep "140-0")" ]]; then
    ytaf="140-0"
elif [[ "$(yt-dlp --list-formats "$1" | grep "140-14")" ]]; then
    ytaf="140-14"
elif [[ "$(yt-dlp --list-formats "$1" | grep "140-drc")" ]]; then
    ytaf="140-drc"
else
    ytaf="140"
fi

## Display video title
echo -e "\n\n==> Fetching: $ytfn\n\n"
sleep 1

## Start the download process
yt-dlp -F $ytdurl
echo -en "\n\nVideo resolution choice? => "
read vf
clear

if [[ $vf -gt 1 ]]; then
    yt-dlp --write-thumbnail --add-metadata --cookies $cookiez -f $vf "$ytdurl" -o '%(title)s.%(ext)s'
    convert "${ytfn}.webp" "${ytfn}.png"
    convert "${ytfn}.png" -resize 150x84^ -gravity center -extent 150x84 "${ytthumb}_150x84.png"
    yt-dlp -f $ytaf "$ytdurl" -o "$ytm4a"
    ffmpeg -i "${ytfn}.mp4" -i "$ytm4a" -c copy "${ytfn}_.mp4"
    rm -f "${ytfn}.mp4"
    rm -f "$ytm4a"
    ffmpeg -i "${ytfn}_.mp4" -i "${ytfn}.png" -map 1 -map 0 -c copy -disposition:0 attached_pic "${ytfn}.mp4"
    if [[ -f "${ytfn}.mp4" ]]; then
        notify-send -u normal -i "$ytviddir/${ytthumb}_150x84.png" "YT Download Complete" "$ytfn"
        #notify-send -u normal -i video "$(echo -e "YT Download Complete:\n$ytfn")"
        sleep 1
        rm -f "${ytviddir}/${ytthumb}_150x84.png"
    else
        notify-send -u normal -i video "$(echo -e "YT Download Failed:\n$ytfn")"
    fi
    mv "${ytfn}.png" "${ytfn}-poster.png"
    rm -f "${ytfn}.webp"
    rm -f "${ytfn}_.mp4"
else
    echo -en "\n\nNo format specified.  This script works best with mp4."
fi
