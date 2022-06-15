#!/bin/bash

base_url='http://localhost:9200'
destination='gs://artemis-elastic-dump/test-2022-06-15-all'

function get_status() {
   index_status=$(curl -s "$base_url/_cat/indices/$1" | awk '{print $1;}')
}

function open_index() {
   echo "open index $1"
   curl -s -X POST "$base_url/$1/_open" > /dev/null
}

function close_index() {
   echo "close index $1"
   curl -s -X POST "$base_url/$1/_close" > /dev/null
}

function confirm_open_index() {
   open_index "$1"
   for run in {1..10}; do 
      get_status "$1"
      if [[ $index_status != "close" ]] ; then
         break
      fi
      sleep 3
   done     
   if [[ $index_status == "close" ]] ; then
      echo "failed to open index $1"
      exit 1
   else
      echo "index $1 opened"
   fi
}

function open_indexes() {
   for idx in $@; do
      confirm_open_index "$idx"
   done
}

function close_indexes() {
   for idx in $@; do
      close_index "$idx"
   done
}

function dump_indexes() {
      
   index_match=$(printf "|^%s$" "$@")
   index_match=${index_match:1}
   echo "dumping indexes ${index_match}"

   ./bin/multielasticdump \
      --fileSize=10mb \
      --size=10000 \
      --gsCompress=true \
      --includeType=data \
      --ignoreChildError=true \
      --direction=dump \
      --limit=8000 \
      --match="$index_match" \
      --input="$base_url" \
      --output="$destination"
}

batchsize=2
readarray -t all_indexes < indexes.txt

for((i=0; i < ${#all_indexes[@]}; i+=batchsize))
do
  batch=( "${all_indexes[@]:i:batchsize}" )
  open_indexes "${batch[@]}"
  dump_indexes "${batch[@]}"
  close_indexes "${batch[@]}"
done

#all_indexes_1=$(printf "|^%s$" "${all_indexes[@]}")
#all_indexes_1=${all_indexes_1:1}

#open_all_indexes

#./bin/multielasticdump \
  #--fileSize=100mb \
  #--gsCompress=true \
  #--includeType=data \
  #--ignoreChildError=true \
  #--direction=dump \
  #--limit=8000 \
  #--match="$all_indexes_1" \
  #--input="$base_url" \
  #--output=gs://artemis-elastic-dump/test-2022-06-14 

#close_all_indexes