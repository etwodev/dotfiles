#!/bin/bash

location="$1"
script_name="${0##*/}"
cachedir="${HOME}/.cache/assets/weather-state"
cachefile="${cachedir}/${script_name}-${location}"

# Create cache directory if needed
mkdir -p "$cachedir"

# Calculate cache age
if [[ -f "$cachefile" ]]; then
    cacheage=$(( $(date +%s) - $(stat -c '%Y' "$cachefile") )) # NOTE: GNU stat
else
    cacheage=9999
fi

# Fetch and cache data if stale or empty
if [[ $cacheage -gt 1740 || ! -s "$cachefile" ]]; then
    if ! curl_output=$(curl -s "https://en.wttr.in/${location}?0qnT"); then
        echo "Error fetching weather data" >&2
        exit 1
    fi

    readarray -t data <<< "$curl_output"

    {
        echo "${data[0]}" | cut -f1 -d,
        echo "${data[1]}" | sed -E 's/^.{15}//'
        echo "${data[2]}" | sed -E 's/^.{15}//'
    } > "$cachefile"
fi

readarray -t weather < "$cachefile"

# Extract temperature and condition
temperature=$(echo "${weather[2]}" | sed -E 's/([[:digit:]]+)\.\./\1 to /g')
condition_text=$(echo "${weather[1]##*,}" | tr '[:upper:]' '[:lower:]')

# Match condition
case "$condition_text" in
    "clear" | "sunny") condition="" ;;
    "partly cloudy") condition="杖" ;;
    "cloudy") condition="" ;;
    "overcast") condition="" ;;
    "mist" | "fog" | "freezing fog") condition="" ;;
    "patchy rain possible" | "patchy light drizzle" | "light drizzle" | \
    "patchy light rain" | "light rain" | "light rain shower" | "rain") condition="" ;;
    "moderate rain at times" | "moderate rain" | "heavy rain at times" | \
    "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | \
    "rain shower") condition="" ;;
    "patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | \
    "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | \
    "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | \
    "light sleet showers" | "moderate or heavy sleet showers") condition="ﭽ" ;;
    "blowing snow" | "moderate or heavy sleet" | "patchy light snow" | \
    "light snow" | "light snow showers") condition="流" ;;
    "blizzard" | "patchy moderate snow" | "moderate snow" | \
    "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | \
    "moderate or heavy snow showers") condition="ﰕ" ;;
    "thundery outbreaks possible" | "patchy light rain with thunder" | \
    "moderate or heavy rain with thunder" | "patchy light snow with thunder") condition="" ;;
    *)
        condition=""
        echo -e "{\"text\":\"$condition\", \"alt\":\"${weather[0]}\", \"tooltip\":\"${weather[0]}: $temperature ${weather[1]}\"}"
        exit 0
        ;;
esac

echo -e "{\"text\":\"$temperature $condition\", \"alt\":\"${weather[0]}\", \"tooltip\":\"${weather[0]}: $temperature ${weather[1]}\"}"
