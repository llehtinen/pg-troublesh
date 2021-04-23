#!/bin/bash
START=$1
END=$2
DATA="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque mi libero, maximus eget ultricies et, pellentesque nec enim. Donec vestibulum ligula vel libero aliquet, at commodo arcu placerat. Sed sed aliquam augue. Vestibulum mattis quam eget gravida."
TABLE=test_data

for i in $(eval echo "{$START..$END}")
do
  echo "INSERT INTO $TABLE (data) VALUES ('$DATA');"
done
