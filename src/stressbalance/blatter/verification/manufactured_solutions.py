#!/usr/bin/env python3

import sympy as sp
from sympy import exp, sin, cos, pi
from sympy.core import S

from blatter import x, y, z

nx, ny, nz = sp.var("n_(x:z)")

N = sp.Matrix([nx, ny, nz])

func_template = "Vector2 {name}({arguments})"

def declare(name, args):
    arguments = ", ".join(["double " + x for x in args])
    print("")
    print((func_template + ";").format(arguments=arguments, name=name))

def define(f_u, f_v, name, args):
    arguments = ", ".join(["double " + x for x in args])

    print("")
    print(func_template.format(arguments=arguments, name=name))

    print("{")

    tmps, (u, v) = sp.cse([f_u, f_v])

    for variable, value in tmps:
        print("  double " + sp.ccode(value, assign_to=variable))

    print("  return {")
    print("    {},".format(sp.ccode(u, standard="c99")))
    print("    {}".format(sp.ccode(v, standard="c99")))
    print("  };")

    print("}")

def main(header=False):
    print("// DO NOT EDIT. This code was generated by a Python script.")

    if header:
        print('#include "pism/util/Vector2.hh"')
    else:
        print("#include <cmath>")
        print("")
        print('#include "manufactured_solutions.hh"')

    print("")
    print("namespace pism {")

    import test_xy
    import test_xz

    test_xy.print_code(header)
    test_xz.print_code(header)

    print("")
    print("} // end of namespace pism")

if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser()
    parser.add_argument("--header", dest="header", action="store_true",
                        help="print function declarations for the header file")

    options = parser.parse_args()

    main(options.header)
