// Copyright (C) 2011, 2012, 2013, 2014 David Maxwell
//
// This file is part of PISM.
//
// PISM is free software; you can redistribute it and/or modify it under the
// terms of the GNU General Public License as published by the Free Software
// Foundation; either version 3 of the License, or (at your option) any later
// version.
//
// PISM is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License
// along with PISM; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

%module(directors="1") cpp

%{
// The material in this section is included verbatim in the C++ source code generated by SWIG.
// The necessary header files required to compile must be included.
// This list is NOT the whole set of headers being wrapped; it is just the list of includes that 
// draws in all the other needed includes as well. See the end of this file for the list
// of PISM headers being wrapped.

#include "PIO.hh"
#include "PISMUnits.hh"
#include "Timeseries.hh"
#include "TerminationReason.hh"
#include "exactTestsIJ.h"
#include "stressbalance/ssa/SSAFEM.hh"
#include "inverse/IP_SSATaucForwardProblem.hh"
#include "inverse/IP_SSAHardavForwardProblem.hh"
#include "inverse/IPDesignVariableParameterization.hh"
#include "inverse/functional/IPFunctional.hh"
#include "inverse/functional/IP_L2NormFunctional.hh"
#include "inverse/functional/IP_H1NormFunctional.hh"
#include "inverse/functional/IPGroundedIceH1NormFunctional.hh"
#include "inverse/functional/IPTotalVariationFunctional.hh"
#include "inverse/functional/IPMeanSquareFunctional.hh"
#include "inverse/functional/IPLogRelativeFunctional.hh"
#include "inverse/functional/IPLogRatioFunctional.hh"
#include "inverse/IP_SSATaucTikhonovGNSolver.hh"
#ifdef PISM_USE_TAO
#include "inverse/TaoUtil.hh"
#include "inverse/IP_SSATaucTaoTikhonovProblem.hh"
#include "inverse/IP_SSATaucTaoTikhonovProblemLCL.hh"
#include "inverse/IP_SSAHardavTaoTikhonovProblem.hh"
#endif
#include "stressbalance/ssa/SSAFD.hh"
#include "pism_python.hh"
#include "iceModel.hh"
#include "SNESProblem.hh"
#include "Mask.hh"
#include "basal_resistance.hh"
#include "enthalpyConverter.hh"
#include "IceGrid.hh"
#include "LocalInterpCtx.hh"
#include "PISMMohrCoulombYieldStress.hh"
#include "pism_options.hh"
#include "SIAFD.hh"
#include "regional/regional.hh"
%}

// SWIG doesn't know about __atribute__ (used, e.g. in pism_const.hh) so we make it ignore it
#define __attribute__(x) 

// Include petsc4py.i so that we get support for automatic handling of PetscErrorCode return values
%include "petsc4py/petsc4py.i"

%include "pism_exception.i"

%typemap(typecheck,precedence=SWIG_TYPECHECK_INTEGER) PetscErrorCode {
   $1 = PyInt_Check($input) ? 1 : 0;
}
%typemap(directorout) PetscErrorCode %{ $result =  PyInt_AsLong($input); %}

// Automatic conversions between std::string and python string arguments and return values
%include std_string.i
// Conversions between python lists and certain std::vector's
%include std_vector.i
%include std_set.i

#ifdef PISM_USE_TR1
#define SWIG_SHARED_PTR_SUBNAMESPACE tr1
#endif
%include <std_shared_ptr.i>

// SWIG seems convinced that it might need to convert a PetscScalar into a 
// complex number at some point, even though it never will.  It issues undesired
// warnings as a consequence of this and some conversion code in petsc4py.i.  
// The following dummy fragments address these warning messages.  We provide
// stubs for doing the conversion, but not the code to do so (since it is not needed).
%fragment(SWIG_AsVal_frag(std::complex<long double>),"header" )
{
}
%fragment(SWIG_From_frag(std::complex<long double>),"header" )
{
}


%template(IntVector) std::vector<int>;
%template(DoubleVector) std::vector<double>;
%template(StringVector) std::vector<std::string>;
%template(StringSet) std::set<std::string>;

// Why did I include this?
%include "cstring.i"

// Lots of Pism objects are returned by passing a reference to a pointer. Use 
//
// %Pism_pointer_reference_typemaps(MyType)
// 
// to declare typemaps so that an argument MyType *&OUTPUT should be treated
// as  an output (so no input variable shows up on the Python side, and
// the output shows up as an output variable).  To apply the typemap
// to all arguments of this type, use 
// %apply MyType *& OUTPUT { MyType *&}
// or use %Pism_pointer_reference_is_always_ouput(MyType) in the first place

%define %Pism_pointer_reference_typemaps(TYPE)
%typemap(in, numinputs=0,noblock=1) TYPE *& OUTPUT (TYPE *temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) TYPE *& OUTPUT
{
    %append_output(SWIG_NewPointerObj(%as_voidptr(*$1), $*descriptor, 0 | %newpointer_flags));
};
%enddef

%define %Pism_pointer_reference_is_always_output(TYPE)
%Pism_pointer_reference_typemaps(TYPE);
%apply TYPE *& OUTPUT { TYPE *&}
%enddef

%define %Pism_pointer_pointer_typemaps(TYPE)
%typemap(in, numinputs=0,noblock=1) TYPE ** OUTPUT (TYPE *temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) TYPE ** OUTPUT
{
    %append_output(SWIG_NewPointerObj(%as_voidptr(*$1), $*descriptor, 0 | %newpointer_flags));
};
%enddef

%define %Pism_pointer_pointer_is_always_output(TYPE)
%Pism_pointer_pointer_typemaps(TYPE);
%apply TYPE ** OUTPUT { TYPE **}
%enddef


%define %Pism_reference_output_typemaps(TYPE)
%typemap(in, numinputs=0,noblock=1) TYPE & OUTPUT (TYPE temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) TYPE & OUTPUT
{
    %append_output(SWIG_NewPointerObj(%as_voidptr($1), $descriptor, 0 | %newpointer_flags));
};
%enddef

%define %Pism_reference_is_always_output(TYPE)
%Pism_reference_output_typemaps(TYPE);
%apply TYPE & OUTPUT { TYPE &}
%enddef



%typemap(in, numinputs=0,noblock=1) bool & OUTPUT (bool temp = false) {
    $1 = &temp;
}
%typemap(argout,noblock=1) bool & OUTPUT
{
    %append_output(SWIG_From(bool)(*$1));
};


%typemap(in, numinputs=0,noblock=1) PETScInt & OUTPUT (PETScInt temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) PETScInt & OUTPUT
{
    %append_output(SWIG_From(int)(*$1));
};

%typemap(in, numinputs=0,noblock=1) std::string& result (std::string temp) {
    $1 = &temp;
}

%typemap(in, numinputs=0,noblock=1) std::string& OUTPUT (std::string temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) std::string & OUTPUT
{
    %append_output(SWIG_FromCharPtr((*$1).c_str()));
}
%apply std::string &OUTPUT { std::string &result}

%typemap(in, numinputs=0,noblock=1) std::vector<int> & OUTPUT (std::vector<int> temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) std::vector<int> & OUTPUT
{
    int len;
    len = $1->size();
    $result = PyList_New(len);
     int i;
     for(i=0; i<len; i++)
     {
         PyList_SetItem($result, i, PyInt_FromLong((*$1)[i]));
     }
}

%typemap(in, numinputs=0,noblock=1) std::vector<double> & OUTPUT (std::vector<double> temp) {
    $1 = &temp;
}
%typemap(argout,noblock=1) std::vector<double> & OUTPUT
{
    int len;
    len = $1->size();
    $result = PyList_New(len);
     int i;
     for(i=0; i<len; i++)
     {
         PyList_SetItem($result, i, PyFloat_FromDouble((*$1)[i]));
     }
}

%typemap(in, numinputs=0, noblock=1) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<TerminationReason> & OUTPUT(TerminationReason::Ptr temp) {
  $1 = &temp;
}
%typemap(argout,noblock=1) SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<TerminationReason> & OUTPUT
{
  {
    SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<  TerminationReason > *smartresult = new SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<  TerminationReason >(*$1);
    %append_output(SWIG_NewPointerObj(%as_voidptr(smartresult), $descriptor, SWIG_POINTER_OWN));
  }
};
%apply SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<TerminationReason> & OUTPUT { SWIG_SHARED_PTR_QNAMESPACE::shared_ptr<TerminationReason> &reason };

%shared_ptr(TerminationReason)
%shared_ptr(KSPTerminationReason)
%shared_ptr(SNESTerminationReason)
%shared_ptr(GenericTerminationReason)
%include "TerminationReason.hh"


%apply std::vector<int> & OUTPUT {std::vector<int> &result};
%apply std::vector<double> & OUTPUT {std::vector<double> &result};
%apply std::vector<std::string> & OUTPUT {std::vector<std::string> & result};
 
%apply int &OUTPUT {int &result};
%apply int *OUTPUT {int *out_mask};

%apply double & OUTPUT {double & result};
%apply double & OUTPUT {double & out};
%apply double * OUTPUT {double * result};
%apply bool & OUTPUT {bool & is_set, bool & result, bool & flag, bool & success};

%Pism_pointer_reference_is_always_output(IceModelVec2S)
%Pism_pointer_reference_is_always_output(IceModelVec2V)
%Pism_pointer_reference_is_always_output(IceModelVec3)

%Pism_pointer_pointer_is_always_output(IceFlowLaw)


// These methods are called from PISM.options.
%rename PISMOptionsInt _optionsInt;
%rename PISMOptionsReal _optionsReal;
%rename PISMOptionsString _optionsString;
%rename PISMOptionsIntArray _optionsIntArray;
%rename PISMOptionsRealArray _optionsRealArray;
%rename PISMOptionsStringArray _optionsStringArray;
%rename PISMOptionsList _optionsList;
%rename PISMOptionsIsSet optionsIsSet;

// The varargs to verbPrintf aren't making it through from python.  But that's ok: we'd like
// to extend the printf features of verbPrintf to include python's formatting for objects.
// So we rename verbPrintf here and call it (without any varargs) from a python verbPrintf.
%rename verbPrintf _verbPrintf;

%extend PISMVars
{
  %pythoncode
  {
    def __init__(self,*args):
      this = _cpp.new_PISMVars()
      try: self.this.append(this)
      except: self.this = this
      if len(args)>1:
        raise ValueError("PISMVars can only be constructed from nothing, an IceModelVec, or a list of such.")
      if len(args)==1:
        if isinstance(args[0],IceModelVec):
          self.add(args[0])
        else:
          # assume its a list of vecs
          for v in args[0]:
            self.add(v)
  }
}

%rename(_regrid) IceModelVec::regrid;
%extend IceModelVec
{
  %pythoncode {
    def regrid(self,filename,critical=False,default_value=0.0):
      if critical == True:
        flag = CRITICAL
      else:
        flag = OPTIONAL
      self._regrid(filename, flag, default_value)
  }
}

// We also make the same fix for IceModelVec2's.
%rename(_regrid) IceModelVec2::regrid;
%extend IceModelVec2
{
  %pythoncode {
    def regrid(self,filename,critical=False,default_value=0.0):
      if critical == True:
        flag = CRITICAL
      else:
        flag = OPTIONAL
      self._regrid(filename, flag, default_value)
  }
}

%rename(read_with_pio) IceModelVec2::read(const PIO&, unsigned int const);

// Shenanigans to allow python indexing to get at IceModelVec entries.  I couldn't figure out a more
// elegant solution.
%extend IceModelVec2S
{
    double getitem(int i, int j)
    {
        return (*($self))(i,j);
    }

    void setitem(int i, int j, double val)
    {
        (*($self))(i,j) = val;
    }

    %pythoncode {
    def __getitem__(self,*args):
        return self.getitem(args[0][0],args[0][1])
    def __setitem__(self,*args):
        if(len(args)==2):
            self.setitem(args[0][0],args[0][1],args[1])
        else:
            raise ValueError("__setitem__ requires 2 arguments; received %d" % len(args));
    }
};

%rename(__mult__) PISMVector2::operator*;
%rename(__add__) PISMVector2::operator+;
%ignore PISMVector2::operator=;
%ignore operator*(const double &a, const PISMVector2 &v1);
%extend PISMVector2
{
  %pythoncode
  {
  def __lmul__(self,a):
    return self.__mul__(self,a)
  }
}

%extend IceModelVec2V
{
    PISMVector2 &getitem(int i, int j)
    {
        return (*($self))(i,j);
    }

    void setitem(int i, int j, PISMVector2 val)
    {
        (*($self))(i,j) = val;
    }

    void setitem(int i, int j, double u, double v)
    {
        (*($self))(i,j).u = u;
        (*($self))(i,j).v = v;
    }

    %pythoncode {
    def __getitem__(self,*args):
        return self.getitem(args[0][0],args[0][1])
    def __setitem__(self,*args):
        if(len(args)==2):
            i=args[0][0]; j=args[0][1]
            val = args[1];
            if(isinstance(val,list) and len(val)==2):
                self.setitem(i,j,val[0],val[1])
            else:
                self.setitem(i,j,val)
        else:
            raise ValueError("__setitem__ requires 2 arguments; received %d" % len(args));
    }
};

%ignore IceModelVec3D::operator();
%extend IceModelVec3D
{

  double getitem(int i, int j, int k)
  {
      return (*($self))(i,j,k);
  }

  void setitem(int i, int j, int k, double val)
  {
      (*($self))(i,j,k) = val;
  }


    %pythoncode {
    def __getitem__(self,*args):
        return self.getitem(args[0][0],args[0][1],args[0][2])

    def __setitem__(self,*args):
        if(len(args)==2):
            self.setitem(args[0][0],args[0][1],args[0][2],args[1])
        else:
            raise ValueError("__setitem__ requires 2 arguments; received %d" % len(args));
    }
};


// FIXME
// IceModelVec2 imports IceModelVec::write with a 'using' declaration,
// and implements a write method with the same signature as one of the
// two IceModelVec::write methods.  This confuses SWIG, which gives a
// warning that the reimplemented IceModelVec2::write is shadowed by the
// IceModelVec::write.  The SWIG generated code actually does the right
// thing, and the warning is wrong.  Trying to reproduce the warning
// in a simple test setting failed.  This should get cleaned up, and
// a bug reported to SWIG if needed.  For now, we do the following hack.
%rename(write_as_type) IceModelVec2::write(std::string,PISM_IO_Type);

%extend Timeseries
{
    %ignore operator[];
    double getitem(unsigned int i)
    {
        return (*$self)[i];
    }
    
    %pythoncode {
    def __getitem__(self,*args):
        return self.getitem(*args)
    }
};


%extend IceGrid
{
    %pythoncode {
    def points(self):
        """Iterate over tuples ``(i,j)`` of nodes owned by the current processor."""
        for i in xrange(self.xs,self.xs+self.xm):
            for j in xrange(self.ys,self.ys+self.ym):
                yield (i,j)
    def points_with_ghosts(self,nGhosts=0):
        for i in xrange(self.xs-nGhosts,self.xs+self.xm+nGhosts):
            for j in xrange(self.ys-nGhosts,self.ys+self.ym+nGhosts):
                yield (i,j)
    def coords(self):
        for i in xrange(self.xs,self.xs+self.xm):
            for j in xrange(self.ys,self.ys+self.ym):
                yield (i,j,self.x[i],self.y[j])
    }
}

/* This is needed to wrap IceGrid::get_dm() */
%apply DM &OUTPUT {DM &result};
/* The following overrides petsc4py's argument checking
for DM & types. For some reason, petsc4py does not allow
a DM=PETSC_NULL to be passed in by reference.  But if pointer variables
are being automatically set to zero, then an output argument might 
in fact be equal to PETSC_NULL, and this is OK. */
%typemap(check,noblock=1) DM& {
  if ($1 == NULL)
    %argument_nullref("$type", $symname, $argnum);
}

// FIXME: the the following code blocks there are explicit calls to Py????_Check.  There seems to 
// be a more elegant solution using SWIG_From(int) and so forth that I'm not familiar with.  The
// following works for now.

// The SWIG builtin typecheck for a const char [] (used, e.g., with overloaded methods) checks that 
// the string is zero length. So we have this bug fix from SWIG developer William Fulton here.
%typemap(typecheck,noblock=1,precedence=SWIG_TYPECHECK_STRING, fragment="SWIG_AsCharPtrAndSize") const char[] {
 int res = SWIG_AsCharPtrAndSize($input, 0, NULL, 0);
 $1 = SWIG_CheckState(res);
}
// Apparently petsc4py doesn't make any typemaps for MPIInts, which PISM uses repeatedly.
%apply int {PetscMPIInt};


// Support for nc_types (e.g. NC_BYTE, etc).  In NetCDF3, an nc_type is an enum, and in 
// NetCDF4 it is typedef'ed to be an int. The enums pose a small problem in C++ because
// you can't assign an arbitrary integer to an enum without a cast, and you can't assume
// even in C that an enum is an int, so you have to be careful about pointers to enums
// versus pointers to ints.  Moreover, I don't know how to grab the definitions from
// netcdf.h here without wrapping everything in the file.
//
// So: we assume that nc_type is an enum.  On input, we force the python input to be an int,
// use pointers to the int variable where needed, and then do a static cast to shove the int
// into an nc_type.  This procedure works correctly if nc_type is an int instead of an enum.
// As for the allowed values, we copy the defines from (NetCDF4) netcdf.h.  No typechecking
// is being done to ensure that a python int on input is a valid nc_type, which isn't good.
// In particular, the allowed values are different in NetCDF4 vs. NetCDF3 (there are more of them.)
// A constraint check to the minimal set of NetCDF3 types would be the right thing to do. (FIXME)
%typemap(in) PISM_IO_Type (int tmp){
    SWIG_AsVal(int)($input,&tmp);
    $1 = static_cast<PISM_IO_Type>(tmp);
}
%typemap(typecheck,precedence=SWIG_TYPECHECK_INTEGER) PISM_IO_Type {
    $1 = PyInt_Check($input);
}

// Tell SWIG that the following variables are truly constant
%immutable PISM_Revision;
%immutable PISM_DefaultConfigFile;

%include "stressbalance/ssa/SNESProblem.hh"
%template(SNESScalarProblem) SNESProblem<1,double>;
%template(SNESVectorProblem) SNESProblem<2,PISMVector2>;

// Now the header files for the PISM source code we want to wrap.
// By default, SWIG does not wrap stuff included from an include file,
// (which is good!) so we need to list every file containing a class
// we want to wrap, including base classes if we want access to base class
// methods
%include "IceGrid.hh"
%feature("valuewrapper") NCVariable;
%feature("valuewrapper") NCSpatialVariable;
%include "NCVariable.hh"
%include "PISMConfig.hh"
%include "pism_const.hh"
%include "pism_options.hh"
%include "Timeseries.hh"
%ignore planeStar::operator[];
%include "iceModelVec.hh"
%include "PISMVars.hh"
%include "PIO.hh"
%ignore PISMUnit::operator=;
%include "PISMUnits.hh"
%include "PISMNCFile.hh"
%include "PISMDiagnostic.hh"
%include "PISMComponent.hh"
%include "basal_resistance.hh"
%include "LocalInterpCtx.hh"
%include "rheology/flowlaws.hh"
%include "enthalpyConverter.hh"
%template(PISMDiag_ShallowStressBalance) PISMDiag<ShallowStressBalance>;
%include "stressbalance/ShallowStressBalance.hh"
%include "SSB_Modifier.hh"
%template(PISMDiag_SIAFD) PISMDiag<SIAFD>;
%include "stressbalance/sia/SIAFD.hh"
%include "flowlaw_factory.hh"

%include "iceModel.hh"

// The template used in SSA.hh needs to be instantiated in SWIG before
// it is used.
%template(PISMDiag_SSA) PISMDiag<SSA>;
%include "stressbalance/ssa/SSA.hh"
%include "stressbalance/ssa/SSAFEM.hh"
%template(PISMDiag_SSAFD) PISMDiag<SSAFD>;
%include "stressbalance/ssa/SSAFD.hh"
%include "Mask.hh"
%include "pism_python.hh"
%template(PISMDiag_PISMMohrCoulombYieldStress) PISMDiag<PISMMohrCoulombYieldStress>;
%include "PISMYieldStress.hh"
%include "PISMMohrCoulombYieldStress.hh"
%include "PISMTime.hh"
%feature("notabstract") SIAFD_Regional;
%include "regional/regional.hh"

%include "inverse/functional/IPFunctional.hh"
%template(IPFunctional2S) IPFunctional< IceModelVec2S >;
%template(IPFunctional2V) IPFunctional< IceModelVec2V >;
%template(IPInnerProductFunctional2S) IPInnerProductFunctional< IceModelVec2S >;
%template(IPInnerProductFunctional2V) IPInnerProductFunctional< IceModelVec2V >;
%include "inverse/functional/IP_L2NormFunctional.hh"
%include "inverse/functional/IP_H1NormFunctional.hh"
%include "inverse/functional/IPGroundedIceH1NormFunctional.hh"
%include "inverse/functional/IPTotalVariationFunctional.hh"
%include "inverse/functional/IPMeanSquareFunctional.hh"
%include "inverse/functional/IPLogRatioFunctional.hh"
%include "inverse/functional/IPLogRelativeFunctional.hh"
%include "inverse/IPDesignVariableParameterization.hh"
%include "inverse/IP_SSATaucForwardProblem.hh"
%include "inverse/IP_SSAHardavForwardProblem.hh"
%include "inverse/IP_SSATaucTikhonovGNSolver.hh"

#ifdef PISM_USE_TAO
%ignore TaoConvergedReasons;
%shared_ptr(TAOTerminationReason)
%include "inverse/TaoUtil.hh"

%include "inverse/IPTaoTikhonovProblem.hh"

#################### IP_SSATauc... #############################

# Instantiate the base class for IP_SSATaucTaoTikhonovProblem
# so that SWIG will implement the base class methods.
%template(IP_SSATaucTaoTikhonovProblemBaseClass)  
          IPTaoTikhonovProblem<IP_SSATaucForwardProblem>;

%shared_ptr(IPTaoTikhonovProblemListener<IP_SSATaucForwardProblem>)

%feature("director") IPTaoTikhonovProblemListener<IP_SSATaucForwardProblem>;

%template(IP_SSATaucTaoTikhonovProblemListener)  IPTaoTikhonovProblemListener<IP_SSATaucForwardProblem>;

%include "inverse/IP_SSATaucTaoTikhonovProblem.hh"

%template(IP_SSATaucTaoTikhonovSolver) TaoBasicSolver<IP_SSATaucTaoTikhonovProblem>;


%shared_ptr(IP_SSATaucTaoTikhonovProblemLCLListener)
%feature("director") IP_SSATaucTaoTikhonovProblemLCLListener;
%include "inverse/IP_SSATaucTaoTikhonovProblemLCL.hh"
%template(IP_SSATaucTaoTikhonovProblemLCLSolver) TaoBasicSolver< IP_SSATaucTaoTikhonovProblemLCL >;


#################### IP_SSAHardav... #############################

%template(IP_SSAHardavTaoTikhonovProblemBaseClass)
          IPTaoTikhonovProblem<IP_SSAHardavForwardProblem>;

%shared_ptr(IPTaoTikhonovProblemListener<IP_SSAHardavForwardProblem>)

%feature("director") IPTaoTikhonovProblemListener<IP_SSAHardavForwardProblem>;

%template(IP_SSAHardavTaoTikhonovProblemListener)
          IPTaoTikhonovProblemListener<IP_SSAHardavForwardProblem>;

%include "inverse/IP_SSAHardavTaoTikhonovProblem.hh"

%template(IP_SSAHardavTaoTikhonovSolver)
          TaoBasicSolver<IP_SSAHardavTaoTikhonovProblem>;

#endif  /* end of ifdef PISM_USE_TAO */


// Tell SWIG that input arguments of type double * are to be treated as return values,
// and that int return values are to be error checked as per a PetscErrorCode.
%apply double *OUTPUT  {double *};
%typemap(out,noblock=1) int {
PyPetsc_ChkErrQ($1); %set_output(VOID_Object);
}
%include "exactTestsIJ.h"
// FIXME! I don't know how to undo the output typemap.
// %typemap(out,noblock=1) int = PREVIOUS;
%clear double *;

