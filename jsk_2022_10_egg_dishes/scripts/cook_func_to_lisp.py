def convert_line_to_lisp(line):
    function_name = line.split('(')[0]
    function_call = line.split('(', 1)[1].rsplit(')', 1)[0]
    arguments = function_call.split(', ', 1)
    lisp_arguments = ""
    for argument in arguments:
        if argument.endswith(')'):
            nested_function_name, nested_lisp_arguments = convert_line_to_lisp(argument + "\n")
            lisp_arguments += "'({} {})".format(nested_function_name, nested_lisp_arguments)
        else:
            lisp_arguments += '"' +  argument + '"' + ' '
    return function_name, lisp_arguments

def convert_to_lisp(input_file, output_file):
    lisp_functions = []
    with open(input_file, 'r') as file:
        for line in file:
            line = line.strip()
            if line:
                function_name, lisp_arguments = convert_line_to_lisp(line)
                lisp_func = '({} {})'.format(function_name, lisp_arguments)
                print(lisp_func)
                lisp_functions.append(lisp_func)
                # lisp_functions.append('({} {})'.format(function_name, lisp_arguments))

    with open(output_file, 'w') as file:
        for lisp_function in lisp_functions:
            file.write('{}\n'.format(lisp_function))

if __name__ == "__main__":
    # テキストファイルのパスを指定して実行
    input_file = '../recipes/converted/butter-sunny-side-up_converted.txt'
    output_file = '../recipes/converted/lisp-converted-butter-sunny-side-up_converted.txt'
    convert_to_lisp(input_file, output_file)
