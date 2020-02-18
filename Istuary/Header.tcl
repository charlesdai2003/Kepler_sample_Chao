#! /bin/env tclsh
# Create By : ChaoYang Dai
#			  chaoyang.dai@istuary.com
#

#Get packages required for script
package require csv
package require struct::matrix

#Resets all registers in PA IP to their default values
proc ResetPAIP {{console 1}} {
	mwr 0x90000000 0x00000001
	if {$console == "1"} {puts "Resetting Please Wait ......"}
	after 9000
	mwr 0x90000000 0x00000000
	after 1000
	if {$console == "1"} {puts "Resetting Complete"}
}

#Initialization of csv into a matrix
#This needs to be run before any other procs
#m is the data structure initialized by ::struct::matrix m
proc InitializeDataMatrix {{console 0}} {
	if {$console == "1"} {puts "Parsing CSV"}
	global m
	set m 1
	global baseAddress
	set baseAddress 0x80000000
	::struct::matrix datamatrix ;#probably a bug with tcl but I get error if I remove this
	::struct::matrix m
	set chan [open [pwd]/conf.csv]
	#set chan [open D:/Header/conf.csv]
	csv::read2matrix $chan m , auto 
	close $chan
	return 
}
proc DestroyDataMatrix {{console 0}} {
	m destroy
	datamatrix destroy
}

#Helper proc to find mask in hex given the width of the field
#Max width 160
# proc GetMask2 {fieldWidth startBit {console 0}} {
	# if {$console == "1"} {puts "Calculating Mask for width of $fieldWidth"}
	# set mask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	# set shiftC [expr {400 - $fieldWidth}]
	# for {set C 0} {$C < $shiftC} {incr C} {
		# set mask [expr {$mask >> 1}]
	# }
	# if {$mask == 0 && $console == 1} {puts "ERROR: FIELDWIDTH TOO HIGH"}
	# for {set C 0} {$C < $startBit} {incr C} {
		# set mask [expr {$mask << 1}]
	# }
	# return [format 0x%4.4llX $mask]
# }
proc GetMask {fieldWidth startBit {console 0}} {
	if {$console == "1"} {puts "Calculated mask for width of $fieldWidth to be [format "0x%llx" [expr round((pow(2,$fieldWidth)-1)) << $startBit]]"}
	return [format "0x%llx" [expr round((pow(2,$fieldWidth)-1)) << $startBit]]
}
#Helper proc to find modifier / offset in hex given info needed
#HATE math in TCL
proc GetMod {startAddress endAddress entryNumber registerWidth {console 0}} {
	set entryNumberM $entryNumber
	set registerWidthM 1
	for {set C $registerWidth} {$C > 32} {set C [expr {$C - 32}]} {
		incr registerWidthM 1
	}
	set entryMod [expr {$entryNumberM*$registerWidthM}]
	set mod [expr {int($entryMod+$startAddress)}]
	if {$console == "1"} {
		if {$mod > [expr {$endAddress}]} { 
			puts "ERROR: MODIFIER LARGER THAN ENDADDRESS"			
		} else {puts "Modifier Generated to be $mod"}
	}
	if {$mod > [expr {$endAddress*32}]} { 
		return 0
	}
	return [format 0x%4.4llX $mod]
}

#Function which returns a list of all the info of a register
#m is the matrix initialized by InitializeDataMatrix
#returns "-1" if a no match for the name of a register is found
proc GetRegInfo {registerName entryNumber {console 0}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set regWidth -1
	set startAddress -1
	set endAddress -1
	set maxEntryNumber -1
	set regAddress -1
	set registerName [string tolower $registerName]
	for {set C 0} {$C < [m rows]} {incr C} {
		if {[string tolower [m get cell 0 $C]] eq $registerName} {
			if {$console == 1} {puts "Register Found"}
			set regWidth [m get cell 3 $C]
			set startAddress [m get cell 6 $C]
			set endAddress [m get cell 7 $C]
			set maxEntryNumber [m get cell 4 $C]
			set regAddress [GetMod $startAddress $endAddress $entryNumber $regWidth $console]
			if {$entryNumber >= $maxEntryNumber} {
				if {$console == 1} {
					puts "ERROR: ENTRY NUMBER TOO HIGH FOR $registerName"					
				}
				return "-1"			
			}
			return [list $registerName $regWidth $maxEntryNumber $startAddress $endAddress $entryNumber $regAddress]
		}
	}
	if {$console == 1} {puts "ERROR: REGISTER $registerName NOT FOUND"}
	return "-1"
}

#Function which returns a list of all the info of a register's field
#m is the matrix initialized by InitializeDataMatrix
#returns "-1" if a no match for the name of a register is found
proc GetFieldInfo {registerName fieldName entryNumber {console 0}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set registerName [string tolower $registerName]
	set fieldName [string tolower $fieldName]
	set regWidth -1
	set fieldWidth -1
	set startAddress -1
	set endAddress -1
	set maxEntryNumber -1
	set fieldStartBit -1
	set fieldAddress -1
	set registerNameT -1
	set fieldNameT -1
	for {set C 1} {$C < [m rows]} {incr C} {
		if {[m get cell 0 $C] ne ""} {
			set regWidth [m get cell 3 $C]
			set startAddress [m get cell 6 $C]
			set endAddress [m get cell 7 $C]
			set maxEntryNumber [m get cell 4 $C]
			set registerNameT [string tolower [m get cell 0 $C]]
		} elseif {[m get cell 1 $C] ne ""} {
			set fieldWidth [m get cell 3 $C]
			set fieldStartBit [m get cell 5 $C]
			set fieldNameT [string tolower [m get cell 1 $C]]			
		}
		if {$registerNameT eq $registerName && $fieldNameT eq $fieldName} {
			if {$console == 1} {puts "Field Found"}
			if {$entryNumber >= $maxEntryNumber} {
				if {$console == 1} {puts "ERROR: ENTRY NUMBER TOO HIGH FOR $registerName"}
				return "-1"
			}
			set fieldAddress [GetMod $startAddress $endAddress $entryNumber $regWidth $console]
			return [list $registerNameT $fieldNameT $regWidth $fieldWidth $maxEntryNumber $fieldStartBit $startAddress $endAddress $entryNumber $fieldAddress]
			
		}
	}
	if {$console == 1} {puts "ERROR: REGISTER $registerName WITH FIELD $fieldName NOT FOUND"}
	return "-1"
}

#Function which actually reads addresses from registers 
proc Read32o {readaddress {console 0}} { return 0x12345678}
proc Read32 {readaddress {console 0}} {
	global baseAddress
	set return [mrd [expr {($readaddress * 4) + $baseAddress}]]
	set return [split $return]
	set return [lindex $return 3]
	return [format 0x%08x 0x$return]
}

#Function which does the actual writes to the registers
proc Write32o {writeaddress writevalue {console 0}} {}
proc Write32 {writeaddress writevalue {console 0}} {
	global baseAddress
	mwr [format 0X%08X [expr {($writeaddress * 4) + $baseAddress}]] [format 0X%08X $writevalue]
}

#Funtion which reads the full register and returns the value of the register
proc ReadRegister {registerName entryNumber {console 0}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set infoList [GetRegInfo $registerName $entryNumber $console]
	set retValue ""
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: READ OF $registerName FAILED"}
		return "-1"
	}
	set rwidth [lindex $infoList 1]
	set caddress [lindex $infoList 6]
	while {$rwidth > 32} {
		if {$console == 1} {puts "$caddress read"}
		set retValue [format %08X [Read32 $caddress $console]]$retValue
		puts $retValue
		incr caddress
		incr rwidth -32
	}
	set mask [GetMask $rwidth 0 $console]
	set tValue [Read32 $caddress $console]
	if {$console == 1} {puts "$caddress read"}
	set tValue [format %4.4llx [expr {$tValue & $mask}]]
	puts $tValue
	set retValue $tValue$retValue
	if {$console == 1} {puts "Register $registerName Read"}
	return [string toupper 0x$retValue]
}

#Function which reads the field of a register and returns the value
proc ReadField {registerName fieldName entryNumber {console 0}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set infoList [GetFieldInfo $registerName $fieldName $entryNumber $console]
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: READ OF $registerName WITH FIELD $fieldName FAILED"}
		return "-1"
	}
	set regValue [ReadRegister $registerName $entryNumber $console]
	set fWidth [lindex $infoList 3]
	set fStartB [lindex $infoList 5]
	set mask [GetMask $fWidth $fStartB $console]
	set value [expr {$mask & $regValue}]
	for {set C $fStartB} {$C > 0} {incr C -1} {
		set value [expr {$value >> 1}]
	}
	if {$console == 1} {puts "Register $registerName with field $fieldName Read"}
	return [string toupper [format 0x%4.4llX $value]]
}

#Function which writes a set value to a specified register
#Default write value is 0X0000000F0000000E0000000D0000000C0000000B0000000A000000090000000800000007000000060000000500000004000000030000000200000001
proc WriteRegister {registerName entryNumber {value 0X0000000F0000000E0000000D0000000C0000000B0000000A000000090000000800000007000000060000000500000004000000030000000200000001} {console 0} } {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set value [string map {" " ""} $value]
	set value [string toupper $value]
	set value [format %0100llX $value]
	set infoList [GetRegInfo $registerName $entryNumber $console]
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: WRITE OF $registerName FAILED"}
		return "-1"
	}
	set rwidth [lindex $infoList 1]
	set caddress [lindex $infoList 6]
	set valuePointer [string length $value]
	while {$rwidth > 32} {
		set startIndex [expr {$valuePointer - 8}]
		set writeValue 0X[string range $value $startIndex $valuePointer]
		if {$console == 1} {puts "Written $writeValue to $caddress"}
		Write32 $caddress $writeValue $console
		incr caddress 1
		incr rwidth -32
		incr valuePointer -9
	}
	set startIndex [expr {$valuePointer - 8}]
	set writeValue 0X[string range $value $startIndex $valuePointer]
	set mask [GetMask $rwidth 0 $console] 
	set writeValue [format 0X%4.4llX [expr {$writeValue & $mask}]]
	if {$console == 1} {puts "Written $writeValue to $caddress"}
	Write32 $caddress $writeValue $console
	if {$console == 1} {puts "Register $registerName Written"}
	return "0"
}

#Function which writes a set value to a specified field of a register
#Default write value is 0x8888888888888888888888888888888888888888888888888888888888888888888888888
proc WriteField {registerName fieldName entryNumber {value 0X0000000F0000000E0000000D0000000C0000000B0000000A000000090000000800000007000000060000000500000004000000030000000200000001} {console 0} } {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set value [string map {" " ""} $value]
	set value [string toupper $value]
	set value [format 0x%0100x $value]
	set value [string toupper $value]
	puts $value
	set infoList [GetFieldInfo $registerName $fieldName $entryNumber $console]
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: WRITE OF $registerName WITH FIELD $fieldName FAILED"}
		return "-1"
	}
	set fWidth [lindex $infoList 3]
	set fStartB [lindex $infoList 5]
	set caddress [lindex $infoList 9]
	set regValue [ReadRegister $registerName $entryNumber $console]
	set mask [GetMask $fWidth $fStartB $console]
	set revmask [GetMask $fWidth $fStartB $console]
	set revmask [format %llx $revmask]
	binary scan [binary format H* $revmask] B* revmask
	set revmask [string map {"0" "a"} $revmask]
	set revmask [string map {"1" "b"} $revmask]
	set revmask [string map {"a" "1"} $revmask]
	set revmask [string map {"b" "0"} $revmask]
	set revmask 0b$revmask
	set revmask [format 0x%4.4llx $revmask]
	puts $revmask
	
	set writeValue [expr {$regValue & $revmask}]
	for {set C $fStartB} {$C > 0} {incr C -1} {
		set value [expr {$value << 1}]
	}
	puts $writeValue
	puts $value
	set writeValue [expr {($value & $mask) | $writeValue}]
	puts $writeValue
	WriteRegister $registerName $entryNumber $writeValue $console
	if {$console == 1} {puts "Register $registerName with field $fieldName Written"}
	return "0"
}


#Informative function which returns the largest field and register in the csv
#Console is defaulted to 1 instead of the expected 0
proc GetLargest {{console 1}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set lFieldSize -1
	set lRegSize -1
	set lFieldName [list "null"]
	set lRegName [list "null"]
	for {set C 1} {$C < [m rows]} {incr C} {
		if {([m get cell 0 $C] ne "") && ([m get cell 3 $C] >= $lRegSize)} {
			if {[m get cell 3 $C] == $lRegSize} {
				set lRegSize [m get cell 3 $C]
				lappend lRegName [m get cell 0 $C]
			} else {
				set lRegSize [m get cell 3 $C]
				set lRegName [list [m get cell 0 $C]]
			}
		} elseif {([m get cell 1 $C] ne "") && ([m get cell 3 $C] >= $lFieldSize)} {
			if {[m get cell 3 $C] == $lFieldSize} {
				set lFieldSize [m get cell 3 $C]
				lappend lFieldName [m get cell 1 $C]
			} else {
				set lFieldSize [m get cell 3 $C]
				set lFieldName [list [m get cell 1 $C]]
			}			
		}
	}
	if {$console == 1} {
		puts "Largest register size is $lRegSize"
		puts "Largest registers are: $lRegName"
		puts "Largest field size is $lFieldSize"
		puts "Largest fields are: $lFieldName"
	}
	return [list $lRegSize $lRegName $lFieldSize $lFieldName]
}

#Reads a register and compares its value to a specified value
#Returns PASS if value matches and returns the value of the register if a match is not made
proc ReadRegisterComp {registerName entryNumber compValue {console 0}} {
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set infoList [GetRegInfo $registerName $entryNumber $console]
	set retValue ""
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: READ OF $registerName FAILED"}
		return "-1"
	}
	set rwidth [lindex $infoList 1]
	set caddress [lindex $infoList 6]
	while {$rwidth > 32} {
		set retValue [format %08X [Read32 $caddress $console]]$retValue
		#puts $retValue
		incr caddress 1
		incr rwidth -32
	}
	set mask [GetMask $rwidth 0 $console]
	set tValue [Read32 $caddress $console]
	set tValue [format %4.4llX [expr {$tValue & $mask}]]
	set retValue $tValue$retValue
	set mask2 [GetMask [lindex $infoList 1] 0 $console]
	set compValue [format 0x%08x [expr {$compValue & $mask2}]]
	set retValue 0x$retValue
	if {$compValue == $retValue} {
		if {$console == 1} {puts "$registerName has expected value of $compValue"}
		return "PASS"
	}
	if {$console == 1} {puts "ERROR: $registerName HAS VALUE OF $retValue WHILE ITS EXPECTED VALUE IS $compValue"}
	return $retValue
}

#Reads a register comparing results to incrementing values based on the first 2 address reads
#Reads all entries of register unless number of address writes is specified
proc ReadRegisterIncrComp {registerName entryNumber {value1 0x1} {value2 0x2} {addrReads 16564566794} {console 0}} {
	set return "0" 
	set counter $value1
	set incrValue [expr {$value2 - $value1}]
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set infoList [GetRegInfo $registerName $entryNumber $console]
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: READ OF $registerName FAILED"}
		return "-1"
	}
	set rwidth [lindex $infoList 1]
	set caddress [lindex $infoList 6]
	set maxaddress [lindex $infoList 4]
	set reads 0
	set readb 0
	while {$reads < $addrReads && $caddress <= $maxaddress} {
		if {[expr {$rwidth - ($readb % $rwidth)}] < 32} {
			set mask [GetMask [expr {$rwidth - ($readb % $rwidth)}] 0 $console]
			set tValue [Read32 $caddress $console]
			set tValue [format %4.4llX [expr {$tValue & $mask}]]
			set eValue [format %4.4llX [expr {$counter & $mask}]]
			set counter [expr {$counter + $incrValue}]
			incr reads 1
			incr readb 32
			incr caddress 1
			if {$tValue != $eValue} {
				if {$console == 1} {puts "ERROR: READ AT ADDRESS $caddress HAS UNEXPECTED VALUE OF $tValue EXPECTED VALUE IS $eValue"}
				set return "-1"
			}
		} else {
			set tValue [Read32 $caddress $console]
			set eValue $counter
			set counter [expr {$counter + $incrValue}]
			incr reads 1
			incr readb 32
			incr caddress 1
			if {$tValue != $eValue} {
				if {$console == 1} {puts "ERROR: READ AT ADDRESS $caddress HAS UNEXPECTED VALUE OF $tValue EXPECTED VALUE IS $eValue"}
				set return "-1"
			}
		}
	}
	if {$console == 1} {puts "$registerName has been read"}
	if {$console == 1 && $caddress >= $maxaddress} {puts "Warning: Max address reached"}
	return $return
}
#Writes incrementing values into a register based on the first 2 pieces of data to write
#Writes all entries of register unless number of address writes is specified
proc WriteRegisterIncr {registerName entryNumber {value1 0x1} {value2 0x2} {addrWrites 16564566794} {console 0}} {
	set counter $value1
	set incrValue [expr {$value2 - $value1}]
	global m
	if {![info exists m]} {
		puts "Error, please call the initialization function first!"
		return -1
	}
	set infoList [GetRegInfo $registerName $entryNumber $console]
	if {$infoList == "-1"} {
		if {$console == 1} {puts "ERROR: READ OF $registerName FAILED"}
		return "-1"
	}
	set caddress [lindex $infoList 6]
	set maxaddress [lindex $infoList 4]
	set writes 0
	while {$writes < $addrWrites && $caddress <= $maxaddress} {
		if {$console == 1} {puts "Written $counter to $caddress"}
		Write32 $caddress $counter $console
		set counter [format 0x%4.4llx [expr {$counter + $incrValue}]]
		incr writes 1
		incr caddress 1
	}
	if {$console == 1} {puts "$registerName has been written"}
	if {$console == 1 && $caddress >= $maxaddress} {puts "Warning: Max address reached"}
	return "0"
}