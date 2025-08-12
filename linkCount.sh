#!/bin/bash
FOLDERS=('Daily Notes' 'Reference notes' 'Week Notes' 'ZettleKasten')
MAX_LINKS=0
VAULT_LOCATION=/home/mat/Obsidian

cd $VAULT_LOCATION
echo "" > holderFile
#I guess I can't sort the file and then place it back in itself, so I create a holder. oh well.

# this loop works by starting at 0, loop condition checks if c is <= the len of FOLDERS array
for (( 0; c<=${#FOLDERS[@]}; c++ ));
do
    for i in ./"${FOLDERS[$c]}"/*.md;
    do
        LINK_NUM=$(cat "$i" | tr '\n' ' ' | sed 's/]]/]]\n/g' | wc -l)
        if [[ $LINK_NUM -le $MAX_LINKS ]]
            #LINK_NAME0=${i##*/}
            #LINK_NAME=${LINK_NAME0$.md}
            then echo "|" ${LINK_NUM} "| [[${i##*/}]] |" >> holderFile
        fi
    done
done

sort -n holderFile > "The Unlinked.md"
sed -i '1s/^/|# of Links|Note|\n| ---- | ---- |/' "The Unlinked.md"




##TODO:
#the Michael Nielsen lit note is having some issues, I think it may be because it's a lit note; not sure though.
#   This is the output I get from the file """ | 0 | [[[[@nielsenAugmentingLongtermMemory2018]].md]] | """
#   I think that removing all of the suffixes would resovle that
#   Also poss that the @ starting notes don't need the brackets



#for some reason I'm getting the right amount of links, without the subtract 1.
#logic is that you remove all new lines, so you by default only have one line.
#if you have no links, you subtract 1 from the line count, boom. correct.
#if there's a single link, a line break is added and line count gives two, -1, one link.
#Well I'll be; "cat linkTest2 | tr '\n' ' ' | wc -l" gives the output....0.....lets try another
#Yeah, starts off with zero. that's weird to me. Don't get it. Oh well, can subtract code

#Ok, so I can do this reliably with one file, next things:

#Be able to loop through all the files recursively in the vault, send file names to the function, whatever
#   Got it to run through an entire folder, and from what I saw, it works :) 
#   Just need to go through the files that I care about. Could do a nested loop, sounds complicated
#       Actually not too bad, make a list of the FOLDERS and they are iterated through in the 2nd layer for loop.
#       lol pick the folder to cd to, link count, cd ..; ITERATE
#I've got a fair amount of files, it'd be cool (not necessary) to test how long it takes.

#TODO (MAYBE)
#Learn to append to an array and then ask for User input?
#   myArray+=( "newElement1" "newElement2" )
#"hi, the currrent searching files are x,y,z; do you want to change?"

#If I wanted to get super crazy, I could add the "execute code from Obsidian" plugin, 
#copy the code needed to run this script and hardcode it above this table stuff
