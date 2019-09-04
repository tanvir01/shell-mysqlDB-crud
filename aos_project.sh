#!/bin/bash

#define db user,password,database name
myUser="root"
export MYSQL_PWD="abcabc"
myDatabase="aos_project"



#function to execute sql queries
runQuery(){
	mysql -u ${myUser} -D ${myDatabase} -e "$1"

	#check if query executed successfully
	if [ $? -eq 0 ]; then
		return 0
	fi

	return 1
}

#function to take input from user and find if a row exists
searchRow(){
	output=("${!1}")
	tableSelectOption="$2"
	echo "Columns Avaible:"
				#show column names to user
				num=1 #skip values : COLUMN_NAME
				while [ $num -lt ${#output[@]} ]; do
					
						column=${output[num]}

						echo "$column"
					
					num=$((num + 1))
				done

				read -p "Enter Column Name (Search Criteria): " columnNameOption

				#validate input : columnNameOption (column must exists)

				while true; do

					num=1 #skip values : COLUMN_NAME
					while [ $num -lt ${#output[@]} ]; do
						
							column=${output[num]}
							# if column name input is correct break the loops, else keep asking for correct column name
							if [ "$column" = "$columnNameOption" ]; then
							  	break 2
							fi
						
						num=$((num + 1))
					done
			        
			        echo "Error, Invalid Column Name"
		  			read -p "Enter Column Name (Search Criteria): " columnNameOption
				done

				read -p "Enter Column Value (Search Criteria Value): " columnValueOption

				#get the row from the table

				#check if no row is returned
				myOutput=()
				while read -r output_line; do
					myOutput+=("$output_line")
				done < <(mysql -u ${myUser} -D ${myDatabase} -e "SELECT * FROM $tableSelectOption WHERE $columnNameOption='$columnValueOption'")
				#echo "There are ${#myOutput[@]} lines returned"
				if (( ${#myOutput[@]}==0 )); then
					return 1
				else
					return 0
				fi
	return 1
}


#read input
echo "Choose An Option"
echo "1. Create Table"
echo "2. Select Table"
echo "3. Delete Table"
read -p "Enter Option: " tableOption

#validate input : tableOption
if (( tableOption==1 )); then
	# read table name
	read -p "Enter Table Name: " tableName
	read -p "Number Of Columns: " numberOfCols

	#validate input : numberOfCols (positive integer greater than 0)

	while ! [[ "$numberOfCols" =~ ^[1-9][0-9]*$ ]] ; do

        echo "Error, please enter a positive integer."
           
    	read -p "Enter a positive integer : " numberOfCols
	
	done


    #read col names and types
    num=1
	columnString="id int NOT NULL AUTO_INCREMENT,"
	while [ $num -le $numberOfCols ]; do
		read -p "Enter column name and type: " columnName columnType

		columnString="$columnString $columnName $columnType,"

		num=$((num + 1))
	done

	columnString="$columnString PRIMARY KEY (id)"
	#echo "columnString: $columnString"

	#run create table command

	if runQuery "CREATE TABLE $tableName ( $columnString )"; then
    	echo "Table Created Successfully"
	else
	    echo "Table Creation Failed"
	fi
	


elif (( tableOption==2 )); then
	######## check if there are tables to select ############
	tableCountOutput=()
	while read -r output_line; do
			tableCountOutput+=("$output_line")
	done < <(mysql -u ${myUser} -D ${myDatabase} -e "SELECT count(*) FROM information_schema.tables WHERE table_schema = '$myDatabase'")
	#echo "There are ${#output[@]} lines returned"
	#printf '%s\n' "${output[@]}"
		
	#get number of tables
	noOfTables=${tableCountOutput[1]}

	if (( noOfTables==0 )); then
		echo "No Table Available"
	else
		#run show tables command
		if runQuery "show tables"; then
	    	read -p "Enter Table Name To Select: " tableSelectOption

	    	###########check if table exists #######################

	    	#validate table name
	    	#run select from table command
	    	runQuery "SELECT 1 FROM $tableSelectOption LIMIT 0;"

			while ! [[ $? -eq 0 ]] ; do
				echo "Error, Table Does Not Exists"
				read -p "Enter Table Name To Select: " tableSelectOption

				#run select from table command
				runQuery "SELECT 1 FROM $tableSelectOption LIMIT 0;"
			done


	    	#fetch user input for operation on table
	    	echo "Choose An Option"
			echo "1. Insert"
			echo "2. Read"
			echo "3. Update"
			echo "4. Delete"
			read -p "Enter Option: " tableOperationOption

			#validate input : tableOperationOption (positive integer 1-4)

			while true; do

		        if [[ $tableOperationOption -ge 1 && $tableOperationOption -le 4 ]] ; then 
	  				break
	  			else
	  				echo "Error, Invalid Option"
	  				read -p "Enter Option: " tableOperationOption
				fi
			
			done

			#get column names of the table
			output=()
			while read -r output_line; do
				output+=("$output_line")
			done < <(mysql -u ${myUser} -D ${myDatabase} -e "SELECT COLUMN_NAME FROM information_schema.columns WHERE table_schema = '$myDatabase' AND table_name = '$tableSelectOption'")
			#echo "There are ${#output[@]} lines returned"


			# Check the value of tableOperationOption
			if (( tableOperationOption==1 )); then
				#### insert ########
				
				#loop through the above array and take col values input from  user
			    num=2 #skip values : COLUMN_NAME & id
			    columnNameString=""
				valueString=""
				while [ $num -lt ${#output[@]} ]; do
					
						column=${output[num]}

						read -p "$column: " columnValue

						columnNameString="$columnNameString $column"
						valueString="$valueString '$columnValue'"

						#do not append the ',' for last value
						if [[ $num -lt ${#output[@]}-1 ]]; then
							valueString="$valueString,"
							columnNameString="$columnNameString,"
						fi
					
					num=$((num + 1))
				done

				#echo "$valueString"
				
				#run insert query command
				if runQuery "INSERT INTO $tableSelectOption ($columnNameString) VALUES ($valueString)"; then
					echo "Insert Successful"
				else
					echo "Insertion Failed"
				fi

			elif (( tableOperationOption==2 )); then
				#read

				#fetch user input for operation on table
		    	echo "Choose An Option"
				echo "1. Read All"
				echo "2. Read Specific"
				read -p "Enter Option: " readOperationOption

				#validate input : readOperationOption (positive integer 1 or 2)

				while true; do

			        if [[ $readOperationOption -eq 1 || $readOperationOption -eq 2 ]] ; then 
		  				break
		  			else
		  				echo "Error, Invalid Option"
		  				read -p "Enter Option: " readOperationOption
					fi
				
				done

				if (( readOperationOption==1 )); then
					#get all rows of the table
					
					#check if the table has any row
					#check if no row is returned
					rowCountOutput=()
					while read -r output_line; do
						rowCountOutput+=("$output_line")
					done < <(mysql -u ${myUser} -D ${myDatabase} -e "SELECT COUNT(*) FROM $tableSelectOption")
					#echo "There are ${#myOutput[@]} lines returned"
					#printf '%s\n' "${rowCountOutput[@]}"
					if (( ${rowCountOutput[1]}==0 )); then
						echo "No Row Found."
					else
						#get all rows of the table
						if runQuery "SELECT * FROM $tableSelectOption"; then
							echo "Showing All Rows.."
						else
							echo "Operation Failed"
						fi
					fi

				else
					#get specific row
					if searchRow output[@] "$tableSelectOption"; then
						
						# run the query to show proper formatted result in display
						if runQuery "SELECT * FROM $tableSelectOption WHERE $columnNameOption='$columnValueOption'"; then
							echo "Showing Row.."
						else
							echo "Operation Failed"
						fi
					else
						echo "No Row Found."
					fi
					
				fi

			elif (( tableOperationOption==3 )); then
				######### update ##############
				#get specific row
				if searchRow output[@] "$tableSelectOption"; then
						# run the query to show proper formatted result in display
						if runQuery "SELECT * FROM $tableSelectOption WHERE $columnNameOption='$columnValueOption'"; then
							read -p "Row Found. Enter Column Name (To Update): " columnNameUpdateOption

							#validate input : columnNameUpdateOption (column must exists)

							while true; do

								num=1 #skip values : COLUMN_NAME
								while [ $num -lt ${#output[@]} ]; do
									
										column=${output[num]}
										# if column name input is correct break the loops, else keep asking for correct column name
										if [ "$column" = "$columnNameUpdateOption" ]; then
										  	break 2
										fi
									
									num=$((num + 1))
								done
						        
						        echo "Error, Invalid Column Name"
					  			read -p "Enter Column Name (To Update): " columnNameUpdateOption
							done

							read -p "Enter Column Value (To Update): " columnValueUpdateOption

							#run update query command
							if runQuery "UPDATE $tableSelectOption SET $columnNameUpdateOption='$columnValueUpdateOption' WHERE $columnNameOption='$columnValueOption'"; then
								echo "Update Successful"
							else
								echo "Update Failed"
							fi
						else
							echo "Operation Failed"
						fi
				else
					echo "No Row Found."
				fi

					
			else
				######## delete ################
				#get specific row
				if searchRow output[@] "$tableSelectOption"; then
					#run delete query command
					if runQuery "DELETE FROM $tableSelectOption WHERE $columnNameOption='$columnValueOption'"; then
						echo "Deletion Successful"
					else
						echo "Deletion Failed"
					fi
				else
					echo "No Row Found."
				fi

				
			fi

		else
		    echo "Operation Failed"
		fi


	fi
	

elif (( tableOption==3 )); then
		######## check if there are tables to delete ############
		output=()
		while read -r output_line; do
			output+=("$output_line")
		done < <(mysql -u ${myUser} -D ${myDatabase} -e "SELECT count(*) FROM information_schema.tables WHERE table_schema = '$myDatabase'")
		#echo "There are ${#output[@]} lines returned"
		#printf '%s\n' "${output[@]}"
		
		#get number of tables
		noOfTables=${output[1]}

		if (( noOfTables==0 )); then
			echo "No Table Available"
		else
			#run show tables command
			if runQuery "show tables"; then

				######## check if there are tables to delete ############
				
		    	read -p "Enter Table Name To Delete: " tableDeleteName

		    	#validate table name
		    	#run select from table command
		    	runQuery "SELECT 1 FROM $tableDeleteName LIMIT 0;"

				while ! [[ $? -eq 0 ]] ; do
					echo "Error, Table Does Not Exists"
					read -p "Enter Table Name To Delete: " tableDeleteName

					#run select from table command
					runQuery "SELECT 1 FROM $tableDeleteName LIMIT 0;"
				done
		    	
				#check if query executed successfully
				if runQuery "DROP TABLE $tableDeleteName"; then
			    	echo "Table Deleted Successfully"

				else
				    echo "Table Deletion Failed"
				fi

			else
			    echo "Operation Failed"
			fi

		fi

else
	echo "Invalid Option"
fi
