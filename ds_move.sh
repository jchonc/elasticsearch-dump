#!/bin/bash

base_url='http://localhost:9200'

all_indexes=("${@}")

closed_indexes=()

function get_status() {
   index_status=$(curl -s "$base_url/_cat/indices/$1" | awk '{print $1;}')
}

function open_index() {
  curl -s -X POST "$base_url/$1/_open" > /dev/null
}

function close_index() {
  curl -s -X POST "$base_url/$1/_close" > /dev/null
}

function open_all_indexes() {
   for idx in ${all_indexes}; do
   get_status "$idx"
   if [[ $index_status == "close" ]] ; then
      echo "opening index $idx"
      open_index "$idx"
      closed_indexes+="$idx"
      for run in {1..10}; do 
         get_status "$idx"
         if [[ $index_status != "close" ]] ; then
         break
         fi
         sleep 2
      done    
      if [[ $index_status == "close" ]] ; then
         echo "failed to open index $idx"
         exit 1
      else
         echo "index $idx opened"
      fi
   fi
   done
}

function close_all_indexes() {
   for idx in ${closed_indexes}; do
   echo "closing index $idx"
   close_index "$idx"
   done
}

all_indexes_1=$(printf "|^%s$" "${all_indexes[@]}")
all_indexes_1=${all_indexes_1:1}

open_all_indexes

./bin/multielasticdump \
  --fileSize=10mb \
  --size=10000 \
  --gsCompress=true \
  --includeType=data \
  --ignoreChildError=true \
  --direction=dump \
  --limit=8000 \
  --match="$all_indexes_1" \
  --input="$base_url" \
  --searchBody=@defaultSearchBody.json \
  --output=gs://test-1300-bucket/dump2 

close_all_indexes