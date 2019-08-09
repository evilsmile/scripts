function trim(str)
{
    sub("^`", "", str)
    sub("`$", "", str)
    return str
}

function to_hump_name(str) 
{
    str = trim(str)
    # a_b_c => a, b, c => A, b, c => Abc
    split(str, array, "_")
    ret_str = ""
    for (i = 1; i <= length(array); i++) {
        first_letter = substr(array[i], 1, 1)
        upper_letter = toupper(first_letter)
        left = substr(array[i], 2, length(array[i]))
        ret_str = ret_str""upper_letter""left
    }
    return ret_str
}

BEGIN {
#    types_go_file = "types.go"
#    registers_go_file = "registers.go"
    print "" > types_go_file
    print "" > registers_go_file
}
{
    if ($0 !~ /(DROP TABLE IF|PRIMARY KEY|INDEX)/) { 
        if ($0 ~ /CREATE TABLE/) {
            split($0, array, " ")
            go_type_name = to_hump_name(array[3])
            print "type",go_type_name,"struct {"  >> types_go_file
            go_types[go_type_name] = 0
        } else if ($0 ~ /ENGINE=InnoDB/) {
            print "}" >> types_go_file
            print "" >> types_go_file
        } else if ($0 ~ /varchar|\<int\>|\<bigint\>|datetime|timestamp/) {
            split($0, array, " ")
            field_name=array[1]
            field_type=array[2]
            new_field_name = to_hump_name(field_name)
            old_field_name = trim(field_name)
            if (field_type ~ /varchar|datetime|timestamp/) {
                new_field_type = "string"
            } else if (field_type ~ /\<int\>/) {
                new_field_type = "int"
            } else if (field_type ~ /\<bigint\>/) {
                new_field_type = "int64"
            } 
            printf("     %s %s `json:\"%s\"`\n", new_field_name, new_field_type, old_field_name) >> types_go_file
        }
    }
}

END {
    for (t in go_types) {
        print "    orm.RegisterModel(new(",t,"))" >> registers_go_file
    }
}
