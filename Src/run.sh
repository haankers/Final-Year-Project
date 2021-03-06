echo "=== BEGINING JULIA FUZZER ==="
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMEFORMAT=%R

JULIA=/Applications/Julia-1.4.app/Contents/Resources/julia/bin/julia
# Declares how many process number
let pro_N=0
let file_counter=0
let timer=0
let lines=0
let error_counter=0
# all print
let v2=1
#v1 no error print
let v1=1
#v1 no print
let v0=1
let noError=0
let mathsCheck=0

# status flags
while [ -n "$1" ]; do # while loop starts

	case "$1" in

    -v2) ;;
	-v1) let v2=0 ;; # Verbose1
	-v0) let v1=0
        let v2=0 ;; # Verbose0
    -p)
		pro_N="$2"

		shift
		;;
	-e) let noError=1 ;; # No error
	-m) let mathsCheck=1 ;; # Maths checks
    -t) let timer=1 ;; #times
    -l) let lines=1 ;; #lines
	*) echo "Option $1 not recognized" ;;

	esac

	shift

done

# Removes all old test files
if [[ ! -d "$DIR/test_files/Process_$pro_N" ]]
then
    mkdir "$DIR/test_files/Process_$pro_N"
    mkdir "$DIR/test_files/Process_$pro_N/log_files"
fi

let start=$(gdate +%s)
while :
do
    let bug=1
    let error=0

    rm -rfv "$DIR/test_files/Process_$pro_N/*.txt" 2>/dev/null
    # Creates the files
    if [ $v2 -ne 1 ]; then
        $JULIA "$DIR/topLevel.jl" "$DIR/test_files/Process_$pro_N/" 2>>"$DIR/test_files/Process_$pro_N/log_files/errlog.txt"
    else 
        $JULIA "$DIR/topLevel.jl" "$DIR/test_files/Process_$pro_N/" 
    fi

    if [ $lines -eq 1 ]; then
        wc -l "$DIR/test_files/Process_$pro_N/File.jl"  | awk '{ print $1 }' >>"$DIR/test_files/Process_$pro_N/log_files/lineslog.txt"
    fi

    # Ran at each opt. level results are stored in variables e.g. o0_return
    if [ $v2 -ne 1 ]; then
        $JULIA "--optimize=0" "$DIR/test_files/Process_$pro_N/File.jl" 1 0 2>>"$DIR/test_files/Process_$pro_N/log_files/errlog.txt"
        let o0_return=$?
    else
        $JULIA "--optimize=0" "$DIR/test_files/Process_$pro_N/File.jl" 1 0
        let o0_return=$?
    fi
    $JULIA "--optimize=1" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 1 2>/dev/null
    let o1_return=$?

    $JULIA "--optimize=2" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 2 2>/dev/null
    let o2_return=$?

    $JULIA "--optimize=3" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 3 2>/dev/null
    let o3_return=$?

    if [ "$mathsCheck" -eq 1 ]; then
        $JULIA "--optimize=3" "--math-mode=ieee" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 4 2>/dev/null
        let o4_return=$?
        $JULIA "--optimize=3" "--math-mode=fast" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 5 2>/dev/null
        let o5_return=$?
    fi

    if [ $timer -eq 1 ]; then
        { echo $o0_return ; echo $o1_return ; echo $o2_return ;
          echo $o3_return ; echo $o4_return ; echo $o5_return ; } >>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=0" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 0 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=1" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 1 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=2" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 2 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=3" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 3 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=3" "--math-mode=ieee" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 4 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { time $JULIA "--optimize=3" "--math-mode=fast" "$DIR/test_files/Process_$pro_N/FILE.jl" 1 5 ; } 2>>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
        { echo "-" ; } >>"$DIR/test_files/Process_$pro_N/log_files/timelog.txt"
    fi
    
    # Checks if file threw an error and if it did inc. the count
    if [ $o0_return -ne 0 ]; then
        error=1
    fi
    # All checks to see if opt. returned different things.
    # If they did inc. count and moves the file
    if [ $o0_return -ne $o1_return ]; then
        echo -e "\nerror diff in File $i o0 / o1 ($o0_return-$o1_return)"
    elif [ $o1_return -ne $o2_return ]; then
        echo -e "\nerror diff in File $i o1 / o2 ($o1_return-$o2_return)"
    elif [ $o2_return -ne $o3_return ]; then
        echo -e "\nerror diff in File $i o2 / o3 ($o2_return-$o3_return)"
    elif [ "$mathsCheck" -eq 1 ] && [ $o3_return -ne $o4_return ]; then
        echo -e "\nerror diff in File $i o3 / o4 ($o3_return-$o4_return)"
    elif [ "$mathsCheck" -eq 1 ] && [ $o4_return -ne $o5_return ]; then
        echo -e "\nerror diff in File $i o4 / o5 ($o4_return-$o5_return)"
    elif [ $o0_return -eq 0 ]; then
        if ! cmp -s "$DIR/test_files/Process_$pro_N/log_files/log0.txt" "$DIR/test_files/Process_$pro_N/log_files/log1.txt"; then
            echo -e "\nlog diff in File $i o0 / o1"
        elif ! cmp -s "$DIR/test_files/Process_$pro_N/log_files/log1.txt" "$DIR/test_files/Process_$pro_N/log_files/log2.txt"; then
            echo -e "\nlog diff in File $i o1 / o2"
        elif ! cmp -s "$DIR/test_files/Process_$pro_N/log_files/log2.txt" "$DIR/test_files/Process_$pro_N/log_files/log3.txt"; then
            echo -e "\nlog diff in File $i o2 / o3"
        elif [ "$mathsCheck" -eq 1 ] && ! cmp -s "$DIR/test_files/Process_$pro_N/log_files/log3.txt" "$DIR/test_files/Process_$pro_N/log_files/log4.txt"; then
            echo -e "\nlog diff in File $i o3 / o4"
        elif [ "$mathsCheck" -eq 1 ] && ! cmp -s "$DIR/test_files/Process_$pro_N/log_files/log4.txt" "$DIR/test_files/Process_$pro_N/log_files/log5.txt"; then
            echo -e "\nlog diff in File $i o4 / o5"
        else
            bug=0
        fi
    else
        bug=0
    fi

    time_tmp=$(gdate +%H\:%M\:%S[%F])
    if [ $bug -eq 1 ]; then
        echo "Bug found!"
        cp "$DIR/test_files/Process_$pro_N/FILE.jl" "$DIR/test_files/bug_files/test_$time_tmp.jl"
        if [ $v0 -eq 1 ]; then
            echo "file \"$time_tmp\" moved to bugs"
        fi
    elif [ $error -eq 1 ]; then
        error_counter=$((error_counter+1))
        if [ $noError -ne 1 ]; then
            cp "$DIR/test_files/Process_$pro_N/FILE.jl" "$DIR/test_files/error_files/test_$time_tmp.jl"
            if [ $v1 -eq 1 ]; then
                echo "file \"$time_tmp\" moved to errors"
            fi
        fi
    fi

    if [[ ($o0_return -ne 0) && ($v2 -eq 1 ) ]]; then
        echo -e "---"
    fi

    let end=$(gdate +%s)
    if [ $v1 -eq 1 ]; then
        file_counter=$((file_counter+1))
        echo -en "done file number - $file_counter [$(bc <<< "scale=2 ; ($end - $start) / $file_counter") per file][$error_counter files errored]\r"
    fi
done