x = parse(Int64, ARGS[1])
(710930702549977358)
#no variables 
tmpLog = open(string("/Users/harrisonankers/Documents/UNI/Year 4/FYP/Src/test_files/Process_0/log_files/log",(ARGS[2]),".txt"), "w")
write(tmpLog, "no Vars", string(x))
close(tmpLog)
