#!/usr/bin/expect -f

set ESXISERVERIP [lindex $argv 0]

set PRIVATEKEY [lindex $argv 1]


set HEADPARTITION ""
set HEADPARTITIONTRUNC ""
set PARTITIONSTRUNC ""
set PARTITIONCOUNT 0
set NEWPARTITION ""
set PARTITIONLISTLENGTH 0
set SEDSTR ""
set MAXSECTOR 0
set ALLEXTENTS 0

set FRMTDPRTTRUNC ""
set FRMTDPRTLIST ""
set FRMTDPRTLISTLTH 0
set PRTSEDSTR ""

set MAX_TRIES 120
set bclineno 160

set timeout 20
set timeout_min 30
set timeout_avg 600
set timeout_mid 3600
set timeout_max 7200

##################################################################################################
#    Description: 
#       This block of code format and then add all avaiable extent(s) to the datastore
#    On Failure: 
#       The extent will not be added but continue to the next line of code
#    On success:
#       Continue add the next available extent
##################################################################################################

spawn ssh -i $PRIVATEKEY -o StrictHostKeyChecking=no root@$ESXISERVERIP
expect -timeout $timeout_min *

set expect_out(buffer) {}

send "vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | awk '{print}' | xargs\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
  set FRMTDPRTTRUNC $expect_out(1,string)
  set FRMTDPRTLIST [split $FRMTDPRTTRUNC " "]
  set FRMTDPRTLISTLTH [llength $FRMTDPRTLIST]
  set PRTSEDSTR ""
  foreach PARTITIONNAME $FRMTDPRTLIST {
   if {$FRMTDPRTLISTLTH > 1} {
   append PRTSEDSTR "s/$PARTITIONNAME.*//g;"
   } else {
   append PRTSEDSTR "s/$PARTITIONNAME.*//g"
   }
  }
  if {$FRMTDPRTLISTLTH > 1} {
  set PRTSEDSTR [string trimright $PRTSEDSTR ";"]
  }
}

send "PARTITNAME=`vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | xargs | awk '{print \$1}'` && EXTENTS=`ls -lrt /vmfs/devices/disks/ | awk '{print \$11}' | sed '-e $PRTSEDSTR' | sed '/^$/d' | wc -l` && echo ==\$EXTENTS==\r"
expect {
   -re "\n==(\\d+)==\r" {set ALLEXTENTS $expect_out(1,string)}
   timeout {set ALLEXTENTS 0}
}

for {set count $ALLEXTENTS} {$count > 0} {incr count -1} {

send "vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | awk '{print}' | xargs\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
  set PARTITIONSTRUNC $expect_out(1,string)
  set PARTITIONLIST [split $PARTITIONSTRUNC " "]
  set PARTITIONLISTLENGTH [llength $PARTITIONLIST]
  set SEDSTR ""

  foreach PARTITIONNAME $PARTITIONLIST {
   if {$PARTITIONLISTLENGTH > 1} {
   append SEDSTR "s/$PARTITIONNAME.*//g;"
   } else {
   append SEDSTR "s/$PARTITIONNAME.*//g"
   }
  }
  if {$PARTITIONLISTLENGTH > 1} {
  set SEDSTR [string trimright $SEDSTR ";"]
  }
}

send "vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | awk 'FNR == 1 {print}'\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
set HEADPARTITION $expect_out(1,string)
}

send "vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | awk 'FNR == 1 {print}'\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
set HEADPARTITIONTRUNC $expect_out(1,string)
}

set expect_out(buffer) {}

send "ls -lrt /vmfs/devices/disks/ | awk '{print \$11}' | sed '-e $SEDSTR' | sed '/^$/d' | awk 'FNR == 1 {print}'\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
set PARTITION $expect_out(1,string) 
}

set expect_out(buffer) {}

send "MAXSECTOR=\$(eval expr \$(partedUtil getptbl /vmfs/devices/disks/$PARTITION | tail -1 | awk '{print \$1 \" \\\\* \" \$2 \" \\\\* \" \$3}') - 1) && echo ==\$MAXSECTOR==\r"
expect -timeout $timeout_min -re "\n==(\\d+)==\r" {
set MAXSECTOR $expect_out(1,string)
}

set expect_out(buffer) {}

send "partedUtil setptbl /vmfs/devices/disks/$PARTITION gpt \"1 2048 $MAXSECTOR AA31E02A400F11DB9590000C2911D1B8 0\"\r"
expect -timeout $timeout_avg *

set expect_out(buffer) {}

send "ls -lrt /vmfs/devices/disks/ | awk '{print \$11}' | grep $PARTITION | awk 'FNR == 1 {print}'\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
set NEWPARTITION $expect_out(1,string)
}

set expect_out(buffer) {}

send "vmkfstools -Z /vmfs/devices/disks/$NEWPARTITION /vmfs/devices/disks/$HEADPARTITION\r"
expect -timeout $timeout_avg "Select a number from 0-1: "

send "0\r"
expect -timeout $timeout_min *

sleep 10

send "vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | awk '{print}' | xargs\r"
expect -timeout $timeout_min -re "\n(naa.+|t10.+)\r" {
  set FRMTDPRTTRUNC $expect_out(1,string)
  set FRMTDPRTLIST [split $FRMTDPRTTRUNC " "]
  set FRMTDPRTLISTLTH [llength $FRMTDPRTLIST]
  set PRTSEDSTR ""
  foreach PARTITIONNAME $FRMTDPRTLIST {
   if {$FRMTDPRTLISTLTH > 1} {
   append PRTSEDSTR "s/$PARTITIONNAME.*//g;"
   } else {
   append PRTSEDSTR "s/$PARTITIONNAME.*//g"
   }
  }
  if {$FRMTDPRTLISTLTH > 1} {
  set PRTSEDSTR [string trimright $PRTSEDSTR ";"]
  }
}

send "PARTITNAME=`vmkfstools -P -h /vmfs/volumes/datastore1 | grep -E '(\\sn.*|\\st.*)' | sed 's/\\t//g' | sed 's/:.$//' | xargs | awk '{print \$1}'` && EXTENTS=`ls -lrt /vmfs/devices/disks/ | awk '{print \$11}' | sed '-e $PRTSEDSTR' | sed '/^$/d' | wc -l` && echo ==\$EXTENTS==\r"
expect {
   -re "\n==(\\d+)==\r" {set ALLEXTENTS $expect_out(1,string)}
   timeout {set ALLEXTENTS 0}
}
}

send "exit\r"
expect eof


