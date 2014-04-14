/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Env
" file:        Env.mo
  package:     Env
  description: Environment management

  RCS: $Id$

  An environment is a stack of frames, where each frame contains a
  number of class and variable bindings.
  Each frame consist of:
  - a frame name (corresponding to the class partially instantiated in that frame)
  - a binary tree containing a list of classes
  - a binary tree containing a list of functions (functions are overloaded so serveral
                 function names can exist)
  - a list of unnamed items consisting of import statements

  As an example lets consider the following Modelica code:
  package A
    package B
     import Modelica.SIunits.;
     constant Voltage V=3.3;
     function foo
     end foo;
     model M1
       Real x,y;
     end M1;
     model M2
     end M2;
   end B;
  end A;

  When instantiating M1 we will first create the environment for its surrounding scope
  by a recursive instantiation on A.B giving the environment:
   {
   FRAME(\"A\", {Class:B},{},{},false) ,
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo},
     {import Modelica.SIunits.},false)
   }

  Then, the class M1 is instantiated in a new scope/Frame giving the environment:
   {
   FRAME(\"A\", {Class:B},{},{},false) ,
   FRAME(\"B\", {Class:M1, Class:M2, Variable:V}, {Type:foo},
     {Import Modelica.SIunits.},false),
   FRAME(\"M1\", {Variable:x, Variable:y},{},{},false)
   }

  NOTE: The instance hierachy (components and variables) and the class hierachy
  (packages and classes) are combined into the same data structure, enabling a
  uniform lookup mechanism "

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import HashTable;
public import SCode;
public import Util;
public import Prefix;

// protected imports
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import Print;
protected import Types;
protected import SCodeDump;
protected import SCodeUtil;
protected import Mod;
protected import Config;

public type Ident = String " An identifier is just a string " ;
public type Env = list<Frame> "an environment is a list of frames";
public type StructuralParameters = tuple<HashTable.HashTable,list<list<DAE.ComponentRef>>>;
public type Import = Absyn.Import;
public type Name = Absyn.Ref;
public type CSetsType = list<tuple<list<DAE.ComponentRef>,DAE.ComponentRef>>;

public constant Env emptyEnv = {};
public constant ImportTable emptyImportTable = IMPORT_TABLE(false, {}, {});

public constant String forScopeName="$for loop scope$" "a unique scope used in for equations";
public constant String forIterScopeName="$foriter loop scope$" "a unique scope used in for iterators";
public constant String parForScopeName="$pafor loop scope$" "a unique scope used in parfor loops";
public constant String parForIterScopeName="$parforiter loop scope$" "a unique scope used in parfor iterators";
public constant String matchScopeName="$match scope$" "a unique scope used by match expressions";
public constant String caseScopeName="$case scope$" "a unique scope used by match expressions; to be removed when local decls are deprecated";
public constant list<String> implicitScopeNames={forScopeName,forIterScopeName,parForScopeName,parForIterScopeName,matchScopeName,caseScopeName};

public uniontype Cache
  record CACHE
    Option<Env> initialEnv "and the initial environment";
    array<DAE.FunctionTree> functions "set of Option<DAE.Function>; NONE() means instantiation started; SOME() means it's finished";
    StructuralParameters evaluatedParams "ht of prefixed crefs and a stack of evaluated but not yet prefix crefs";
    Absyn.Path modelName "name of the model being instantiated";
    Absyn.Program program "send the program around if we don't have a symbol table";
  end CACHE;
  record NO_CACHE
  end NO_CACHE;
end Cache;

public uniontype ScopeType
  record FUNCTION_SCOPE end FUNCTION_SCOPE;
  record CLASS_SCOPE end CLASS_SCOPE;
  record PARALLEL_SCOPE end PARALLEL_SCOPE;
end ScopeType;

public uniontype ImportTable
  record IMPORT_TABLE
    // Imports should not be inherited, but removing them from the environment
    // when doing lookup through extends causes problems for the lookup later
    // on, because for example components may have types that depends on
    // imports.  The hidden flag allows the lookup to 'hide' the imports
    // temporarily, without actually removing them.
    Boolean hidden "If true means that the imports are hidden.";
    list<Import> qualifiedImports;
    list<Import> unqualifiedImports;
  end IMPORT_TABLE;
end ImportTable;

public uniontype FrameType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
  record IMPLICIT_SCOPE "This scope contains one or more iterators; they are made unique by the following index (plus their name)" Integer iterIndex; end IMPLICIT_SCOPE;
end FrameType;

public
type Modifications = list<Modification>;

public uniontype Modification
  record M
    Prefix.Prefix p;
    Absyn.Ident n "the name of the component or class generating this scope";
    Absyn.ArrayDim d "the array dimensions of the component or class generating this scope";
    DAE.Mod m "the modifier sent down";
    Env e "the environment from where mod was sent down";
    list<list<DAE.Subscript>> i "the inst dims";
  end M;
end Modification;

public uniontype Extra
  record EXTRA
    Modifications mods       "Includes the scope specifics, mods, prefix, ad";
    Integer       typeLength "How long is the type env appended to the compnent env";
  end EXTRA;
end Extra;

constant Extra emptyExtra = EXTRA({}, -1);

public
uniontype Frame
  record FRAME
    Option<Ident>         name               "Optional class/component/extends name";
    Option<ScopeType>     scopeType          "Optional scope type";
    FrameType             frameType          "Normal, Encapsulated, Implicit";
    AvlTree               clsAndVars         "List of uniquely named classes and variables";
    AvlTree               types              "List of types, which DOES NOT need to be uniquely named, eg. size may have several types";
    CSetsType             connectionSet      "Current connection set crefs";
    list<SCode.Element>   defineUnits        "List of units defined in the frame";
    ImportTable           importTable        "The Import table";
    Extra                 extra              "Contains more info, see Extra";
    Env                   parents            "Contains the parent environments"; 
  end FRAME;  
end Frame;

public uniontype ItemType
  record USERDEFINED end USERDEFINED;
  record BUILTIN end BUILTIN;
  record BASIC_TYPE end BASIC_TYPE;
  record CLASS_EXTENDS end CLASS_EXTENDS;
end ItemType;

public uniontype InstStatus
"Used to distinguish between different phases of the instantiation of a component
A component is first added to environment untyped. It can thereafter be instantiated to get its type
and finally instantiated to produce the DAE. These three states are indicated by this datatype."

  record VAR_UNTYPED "Untyped variables, initially added to env"
  end VAR_UNTYPED;

  record VAR_TYPED "Typed variables, when instantiation to get type has been performed"
  end VAR_TYPED;

  record VAR_DAE "Typed variables that also have been instantiated to generate dae. Required to distinguish
                  between typed variables without DAE to know when to skip multiply declared dae elements"
  end VAR_DAE;
end InstStatus;

public
uniontype Item
  record VAR
    DAE.Var instantiated "instantiated component" ;
    SCode.Element var "declaration";
    DAE.Mod mod "modification";
    InstStatus instStatus "if it untyped, typed or fully instantiated (dae)";
    Env env "The environment of the instantiated component. Contains e.g. all sub components and functions";
    ItemType itemType;
  end VAR;

  record CLASS
    SCode.Element cls "the class";
    Env env "contains the enclosing scope";
    ItemType itemType "the item type, user defined or builtin";
  end CLASS;

  record TYPE
    list<DAE.Type> tys "list since several types with the same name can exist in the same scope (overloading)" ;
  end TYPE;

  record IMPORT "not really pushed in the frame, just to unify the env management"
    SCode.Element i;
  end IMPORT;
  
  record PARENT
    Absyn.Path name;
    Env parentEnv;
    SCode.Element childClass;
    Env childEnv;
    Modification m;
  end PARENT;
  
end Item;

public function emptyCache 
"returns an empty cache"
  output Cache cache;
protected
  array<DAE.FunctionTree> instFuncs;
  StructuralParameters ht;
algorithm
  instFuncs := arrayCreate(1, DAE.emptyFuncTree);
  ht := (HashTable.emptyHashTableSized(BaseHashTable.lowBucketSize),{});
  cache := CACHE(NONE(),instFuncs,ht,Absyn.IDENT("##UNDEFINED##"),Absyn.dummyProgram);
end emptyCache;


public function noCache "returns an empty cache"
  output Cache cache;
algorithm
  cache := NO_CACHE();
end noCache;

// functions for dealing with the environment
public function newEnvironment
"Returns a new environment with only one frame."
  input Option<SCode.Ident> inName;
  output Env outEnv;
protected
  Frame new_frame;
algorithm
  new_frame := newFrame(inName, NONE(), NORMAL_SCOPE());
  outEnv := {new_frame};
end newEnvironment;

public function newFrame
"This function creates a new frame, which
  includes setting up the hashtable for the
  frame."
  input Option<Ident> inName;
  input Option<ScopeType> inScopeType;
  input FrameType inFrameType;
  output Frame outFrame;
protected
  AvlTree tys;
  AvlTree clsAndVars;
  ImportTable imps;
algorithm
  clsAndVars := emptyAvlTree;
  tys        := emptyAvlTree;
  imps       := emptyImportTable;
  outFrame   := FRAME(inName,inScopeType,inFrameType,clsAndVars,tys,{},{},imps,emptyExtra,{});
end newFrame;

public function newImportTable
"Creates a new import table."
  output ImportTable outImports;
algorithm
  outImports := emptyImportTable;
end newImportTable;

public function isTyped
"author BZ 2008-06
  This function checks wheter an InstStatus is typed or not.
  Currently used by Inst.updateComponentsInEnv."
  input InstStatus is;
  output Boolean b;
algorithm
  b := matchcontinue(is)
    case(VAR_UNTYPED()) then false;
    case(_) then true;
  end matchcontinue;
end isTyped;

public function openScope
"Opening a new scope in the environment means adding a new frame on
  top of the stack of frames. If the scope is not the top scope a classname
  of the scope should be provided such that a name for the scope can be
  derived, see nameScope."
  input Env inEnv;
  input SCode.Encapsulated encapsulatedPrefix;
  input Option<Ident> inIdent;
  input Option<ScopeType> inScopeType;
  output Env outEnv;
protected
  Frame f;
  FrameType frameType;
  Modifications mods;
algorithm
  frameType := getFrameType(encapsulatedPrefix);
  f := newFrame(inIdent, inScopeType, frameType);
  mods := getModifications(inEnv);
  outEnv := f :: inEnv;
  outEnv := addModifications(outEnv, mods);
end openScope;

public function openScopeForClass
"Opening a new scope in the environment means adding a new frame on
  top of the stack of frames. If the scope is not the top scope a classname
  of the scope should be provided such that a name for the scope can be
  derived, see nameScope."
  input Env inEnv;
  input SCode.Element inClass;
  output Env outEnv;
protected
  SCode.Encapsulated enc;
  SCode.Restriction r;
  Ident n;
algorithm
  SCode.CLASS(name = n, encapsulatedPrefix = enc, restriction = r) := inClass;
  outEnv := openScope(inEnv, enc, SOME(n), restrictionToScopeType(r));
end openScopeForClass;

protected function getFrameType
  "Returns a new FrameType given if the frame should be encapsulated or not."
  input SCode.Encapsulated encapsulatedPrefix;
  output FrameType outType;
algorithm
  outType := match(encapsulatedPrefix)
    case SCode.ENCAPSULATED() then ENCAPSULATED_SCOPE();
    else then NORMAL_SCOPE();
  end match;
end getFrameType;

public function inForLoopScope "returns true if environment has a frame that is a for loop"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
    local String name;

    case(FRAME(name = SOME(name))::_)
      equation
        true = stringEq(name, forScopeName);
      then true;

    case(_) then false;

  end matchcontinue;
end inForLoopScope;

public function inForOrParforIterLoopScope "returns true if environment has a frame that is a for iterator 'loop'"
  input Env env;
  output Boolean res;
algorithm
  res := matchcontinue(env)
    local String name;

    case(FRAME(name = SOME(name))::_)
      equation
        true = stringEq(name, forIterScopeName);
      then true;

    case(FRAME(name = SOME(name))::_)
      equation
        true = stringEq(name, parForIterScopeName);
      then true;

    case(_) then false;
  end matchcontinue;
end inForOrParforIterLoopScope;

public function stripForLoopScope "strips for loop scopes"
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local String name; Env env;
    case(FRAME(name = SOME(name))::env)
      equation
        true = stringEq(name, forScopeName);
        env = stripForLoopScope(env);
      then env;
    case(env) then env;
  end matchcontinue;
end stripForLoopScope;

public function getScopeName " Returns the name of a scope, if no name exist, the function fails."
  input Env inEnv;
  output Ident name;
algorithm
  name:= match (inEnv)
    case ((FRAME(name = SOME(name))::_)) then (name);
  end match;
end getScopeName;

public function getScopeNames " Returns the name of a scope, if no name exist, the function fails."
  input Env inEnv;
  output list<String> names;
algorithm
  names := match (inEnv)
    local
      String name;
      Env rest;
    // empty list
    case ({}) then {};
    // frame with a name
    case ((FRAME(name = SOME(name)):: rest))
      equation
        names = getScopeNames(rest);
      then name::names;
    // frame without a name
    case ((FRAME(name = NONE())::rest))
      equation
        names = getScopeNames(rest);
      then "-NONAME-"::names;
  end match;
end getScopeNames;

public function updateEnv
"fold the modifications from the last frame to the rest of the env"
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      Ident               id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra extra;
      Env fs,env,parents;
      Frame fr;
      SCode.Element c;
      ItemType ity;
      Item old;

    case({fr}) then {fr};

    case((FRAME(SOME(id),st,ft,clsAndVars,tys,crs,du,it,extra,parents))::fs)
      equation
        (CLASS(c, _, ity)) = getItemInEnv(id, fs);
        fs = replaceFrameItem(fs, SCode.elementName(c), CLASS(c, fs, ity), {});
        fs = updateEnv(fs);
      then
        FRAME(SOME(id),st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    else inEnv;

  end matchcontinue;
end updateEnv;

public function updateEnvClasses
"updates the classes of the top frame on the env passed
 as argument to the environment passed as second argument"
  input Env inEnv;
  input Env inClassEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEnv, inClassEnv)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra extra;
      Env fs, parents;

    case(FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _)
      equation
        clsAndVars = updateEnvClassesInTree(clsAndVars, inClassEnv);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

  end match;
end updateEnvClasses;

protected function updateEnvClassesInTree
"Help function to updateEnvClasses"
  input AvlTree tree;
  input Env classEnv;
  output AvlTree outTree;
algorithm
  outTree := matchcontinue(tree,classEnv)
    local
      SCode.Element cl;
      Option<AvlTree> l,r;
      AvlKey k;
      Env env;
      Item item;
      Integer h;
      ItemType it;

   // Classes
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,_,it))),h,l,r),_)
     equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
     then
       AVLTREENODE(SOME(AVLTREEVALUE(k,CLASS(cl,classEnv,it))),h,l,r);

   // Other items
   case(AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r),_)
     equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
     then
       AVLTREENODE(SOME(AVLTREEVALUE(k,item)),h,l,r);

   // nothing
   case(AVLTREENODE(NONE(),h,l,r),_)
     equation
      l = updateEnvClassesInTreeOpt(l,classEnv);
      r = updateEnvClassesInTreeOpt(r,classEnv);
     then
       AVLTREENODE(NONE(),h,l,r);

  end matchcontinue;
end updateEnvClassesInTree;

protected function updateEnvClassesInTreeOpt "Help function to updateEnvClassesInTree"
  input Option<AvlTree> tree;
  input Env classEnv;
  output Option<AvlTree> outTree;
algorithm
  outTree := match(tree,classEnv)
    local AvlTree t;
    case(NONE(),_) then NONE();
    case(SOME(t),_)
      equation
        t = updateEnvClassesInTree(t,classEnv);
      then
        SOME(t);
  end match;
end updateEnvClassesInTreeOpt;

public function extendFrameC
"This function adds a class definition to the environment.
 Enumeration are expanded from a list into a class with components"
  input Env inEnv;
  input SCode.Element inClass;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inClass)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      Env fs, env, parents;
      SCode.Element c;
      Ident n;
      ItemType ct;
      SCode.ClassDef cdef;
      Extra extra;

    case (env as FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, SCode.CLASS(name = n))
      equation
        c = SCodeUtil.expandEnumerationClass(inClass);
        cdef = SCode.getClassDef(c);
        ct = getItemType(cdef,NONE());
        clsAndVars = avlTreeAdd(clsAndVars,n,CLASS(c,env,ct));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    case (_,_)
      equation true = Flags.isSet(Flags.FAILTRACE);
        n = SCode.elementName(inClass);
        print("- Env.extendFrameC failed on element: " +& n +& "\n");
      then
        fail();
  end matchcontinue;
end extendFrameC;

public function extendFrameCBuiltin
"This function adds a builtin class definition to the environment."
  input Env inEnv;
  input SCode.Element inClass;
  output Env outEnv;
algorithm
  outEnv := extendFrameCItemType(inEnv,inClass,BUILTIN());
end extendFrameCBuiltin;

public function extendFrameCItemType
"This function adds a class definition to the environment with the given class type.
 Enumeration are expanded from a list into a class with components"
  input Env inEnv;
  input SCode.Element inClass;
  input ItemType inItemType;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inClass,inItemType)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      Env fs, env, parents;
      SCode.Element c;
      Ident n;
      Extra extra;

    case (env as FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, SCode.CLASS(name = n), _)
      equation
        c = SCodeUtil.expandEnumerationClass(inClass);
        clsAndVars = avlTreeAdd(clsAndVars,n,CLASS(c,env,inItemType));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    case (_,_,_)
      equation true = Flags.isSet(Flags.FAILTRACE);
        n = SCode.elementName(inClass);
        print("- Env.extendFrameCItemType failed on element: " +& n +& "\n");
      then
        fail();
  end matchcontinue;
end extendFrameCItemType;

public function updateFrameC "This function updates a component already added to the environment, but
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use."
  input Env inEnv;
  input SCode.Element inClass;
  input Env inClassEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inClass,inClassEnv)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      Env fs,  frames, classEnv, oldCE, parents;
      SCode.Element e, oldE;
      Ident n;
      ItemType oldCT,clsTy;
      SCode.ClassDef cdef;
      Extra extra;
      Item oldItem;

    /*
    case (env, e, classEnv)
      equation
        // Debug.fprintln(Flags.INST_TRACE, "Updating class: " +& valueStr(CLASS(e, classEnv)) +& "\nIn env/cenv:" +& printEnvPathStr(env) +& "/" +& printEnvPathStr(classEnv));
      then
        fail();*/

    // empty case

    case ({}, _, _) then {};

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, e as SCode.CLASS(name = n), classEnv)
      equation
        cdef = SCode.getClassDef(e);
        clsTy = getItemType(cdef, NONE());
        oldItem = avlTreeGet(clsAndVars, n);
        clsAndVars = avlTreeAdd(clsAndVars, n, CLASS(e, classEnv, clsTy));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    // Also check frames above, e.g. when variable is in base class
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, e, classEnv)
      equation
        true = isImplicitScope(id);
        frames = updateFrameC(fs, e, classEnv);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::frames;

    case (_, e, _)
      equation
        print("- Env.updateFrameC failed on class: " +& SCodeDump.unparseElementStr(e,SCodeDump.defaultOptions) +& "\n");
      then
        fail();

  end matchcontinue;
end updateFrameC;

public function extendFrameClasses
"Adds all builtin clases in a Program to the environment."
  input Env inEnv;
  input SCode.Program inProgram;
  input Option<ItemType> inItemType;
  output Env outEnv;
algorithm
  outEnv := match (inEnv, inProgram, inItemType)
    local
      Env env;
      SCode.Element c;
      list<SCode.Element> cs;

    case (env, {}, _) then env;

    case (env, c :: cs, _)
      equation
        env = extendFrameCBuiltin(env, c);
        env = extendFrameClasses(env, cs, inItemType);
      then
        env;

  end match;
end extendFrameClasses;

public function getItemType
  "Returns a class's type."
  input SCode.ClassDef inClassDef;
  input Option<ItemType> inItemType;
  output ItemType outType;
algorithm
  outType := match(inClassDef, inItemType)
    local ItemType itemType;
    
    // A builtin class.
    case (_, SOME(itemType)) then itemType;
    case (SCode.PARTS(externalDecl = SOME(SCode.EXTERNALDECL(lang = SOME("builtin")))), _) then BUILTIN();
    
    // A user-defined class (i.e. not builtin).
    else then USERDEFINED();
  end match;
end getItemType;

public function removeComponentsFromFrameV
"This function removes all components from frame."
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match (inEnv)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra extra;
      Env fs,parents;

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs)
      equation
        // make an empty component env!
        clsAndVars = emptyAvlTree;
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

  end match;
end removeComponentsFromFrameV;

public function extendFrameV "This function adds a component to the environment."
  input Env inEnv;
  input DAE.Var inVar;
  input SCode.Element inVarEl;
  input DAE.Mod inMod;
  input InstStatus instStatus;
  input Env inCompEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inVar,inVarEl,inMod,instStatus,inCompEnv)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars, tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      InstStatus i;
      DAE.Var v;
      Ident n;
      SCode.Element c;
      Env fs,coenv,parents;
      DAE.Mod m;
      Extra extra;
      ItemType itty;

    // Environment of component
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, v as DAE.TYPES_VAR(name = n),c,m,i,coenv)
      equation
        clsAndVars = avlTreeAdd(clsAndVars, n, VAR(v,c,m,i,coenv,USERDEFINED()));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    // Variable already added, perhaps from baseclass
    case (FRAME(clsAndVars  = clsAndVars)::_,DAE.TYPES_VAR(name = n),_,_,_,_)
      equation
        _ = avlTreeGet(clsAndVars, n);
      then
        inEnv;
  end matchcontinue;
end extendFrameV;

public function updateFrameV "This function updates a component already added to the environment, but
  that prior to the update did not have any binding. I.e this function is
  called in the second stage of instantiation with declare before use."
  input Env inEnv;
  input DAE.Var inVar;
  input InstStatus instStatus;
  input Env inCompEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inVar,instStatus,inCompEnv)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      InstStatus i;
      Env fs,coenv,frames,parents;
      DAE.Var v;
      Ident n;
      AvlValue var;
      SCode.Element c;
      DAE.Mod m;
      Extra extra;
      ItemType itty;

    // fully instantiated env of component
    case ({},_,_,_) then {};

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, v as DAE.TYPES_VAR(name = n), i, coenv)
      equation
        (VAR(_,c,m,_,_,itty)) = avlTreeGet(clsAndVars, n);
        //Debug.bprint(not Config.acceptMetaModelicaGrammar(), "UE: " +& printEnvPathStr(inEnv) +& "\n");
        //Debug.bprint(not Config.acceptMetaModelicaGrammar(), "NV: " +& valueStr(VAR(v,c,m,i,coenv,itty)) +& "\n");
        //Debug.bprint(not Config.acceptMetaModelicaGrammar(), "PV: " +& valueStr(var) +& "\n");
        clsAndVars = avlTreeAdd(clsAndVars, n, VAR(v,c,m,i,coenv,itty));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    // Also check frames above, e.g. when variable is in base class
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs,v as DAE.TYPES_VAR(name = _), i, coenv)
      equation
        true = isImplicitScope(id);
        frames = updateFrameV(fs, v, i, coenv);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::frames;

    case (_,DAE.TYPES_VAR(name = _),_,_)
      equation
        /*print("- Env.updateFrameV failed on variable: " +&
              n +& "\n" +& Types.printVarStr(v) +&
              "\nin env:" +& getEnvNameStr(inEnv) +&
              "\nin cenv:" +& getEnvNameStr(inCompEnv) +&
              "\n");*/
      then
        inEnv;
  end matchcontinue;
end updateFrameV;

public function extendFrameT "This function adds a type to the environment.  Types in the
  environment are used for looking up constants etc. inside class
  definitions, such as packages.  For each type in the environment,
  there is a class definition with the same name in the
  environment."
  input Env inEnv;
  input Ident inIdent;
  input DAE.Type inType;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv,inIdent,inType)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      ImportTable it;
      Env fs, parents;
      list<DAE.Type> tps;
      Ident n;
      DAE.Type t;
      Extra extra;

    // Other types with that name already exist, add this type as well
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs,n,t)
      equation
        TYPE(tps) = avlTreeGet(tys, n);
        tys = avlTreeReplace(tys, n, TYPE(t::tps));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    // No other types exists
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs,n,t)
      equation
        failure(TYPE(_) = avlTreeGet(tys, n));
        tys = avlTreeAdd(tys, n, TYPE({t}));
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;
  end matchcontinue;
end extendFrameT;

public function extendFrameI
"Adds an import statement to the environment."
  input Env inEnv;
  input SCode.Element inImport;
  output Env outEnv;
algorithm
  outEnv := match (inEnv,inImport)
    local Env env;
    case (_, _)
      equation
        env = extendEnvWithImport(inImport, inEnv);
      then
        env;
  end match;
end extendFrameI;

public function addFrameItem 
" This function replaces an item in the environment!"
  input Env inEnv;
  input Ident inName;
  input Item inNewItem;
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv, inName, inNewItem)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra extra;
      Env fs, env, parents;
      SCode.Element e;
      Item oldItem, newItem;

    case (_, _, IMPORT(e))
      equation
        env = extendEnvWithImport(e, inEnv);
      then
        env;

    // not there, add it
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _, _)
      equation
        clsAndVars = avlTreeAdd(clsAndVars, inName, inNewItem);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

  end matchcontinue;
end addFrameItem;

public function replaceFrameItem 
" This function replaces an item in the environment!"
  input Env inEnv;
  input Ident inName;
  input Item inNewItem;
  input Modifications inMods "the reason for this push or {} if just for fun";
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv, inName, inNewItem, inMods)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;      
      ImportTable         it;
      Extra extra;
      Env fs, env, parents;
      SCode.Element e;
      Item oldItem, newItem;

    case (_, _, IMPORT(e), _)
      equation
        env = extendEnvWithImport(e, inEnv);
      then
        env;

    // not there, add it
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _, _, _)
      equation
        clsAndVars = avlTreeAdd(clsAndVars, inName, inNewItem);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

  end matchcontinue;
end replaceFrameItem;

public function pushFrameItem 
" This function adds an item to the environment or updates it if is already there!"
  input Env inEnv;
  input Ident inName;
  input Item inNewItem;
  input Modifications inMods "the reason for this push or {} if just for fun";
  output Env outEnv;
algorithm
  outEnv := matchcontinue (inEnv, inName, inNewItem, inMods)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra               extra;
      Env fs, env, parents;
      SCode.Element e;
      Item oldItem, newItem;

    case (_, _, IMPORT(e), _)
      equation
        env = extendEnvWithImport(e, inEnv);
      then
        env;

    // already here, merge
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _, _, _)
      equation
        oldItem = avlTreeGet(clsAndVars, inName);
        newItem = mergeItems(inNewItem, oldItem, inMods);
        clsAndVars = avlTreeAdd(clsAndVars, inName, newItem);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

    // not there, add it
    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _, _, _)
      equation
        clsAndVars = avlTreeAdd(clsAndVars, inName, inNewItem);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;

  end matchcontinue;
end pushFrameItem;

public function mergeItems
"@author: adrpo
 merge items and adds the old one to the history of the new one"
  input Item inNewItem;
  input Item inOldItem;
  input Modifications inMods;
  output Item outItem;
algorithm
  outItem := match(inNewItem, inOldItem, inMods)
    case (_, _, _) then inNewItem;
  end match;
end mergeItems;

public function isComponentFrame 
"returns true if this a virtual component name added during instantiation"
  input Frame inFrame;
  output Boolean b;
algorithm
  b := match(inFrame)
    local Integer tyLen;

    case (FRAME(extra = EXTRA(_, tyLen)))
      equation
        b = intNe(tyLen, -1);
      then 
        b;
    
    else false;
  end match;
end isComponentFrame;

public function setEnvName 
 "set the name in the env"
   input Env inEnv;
   input Option<Ident> inEnvName;
   output Env outEnv;
algorithm
  outEnv := match(inEnv,inEnvName)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra               extra;
      Env fs, env, parents;
 
     // empty case
    case ({}, _) then {};
 
    case (FRAME(_,st,ft,clsAndVars,tys,_,_,it,extra,parents)::fs, _)
      equation
        clsAndVars = emptyAvlTree;
        tys        = emptyAvlTree;
        it         = emptyImportTable;
      then
        //FRAME(inEnvName,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;
        FRAME(inEnvName,st,ft,clsAndVars,tys,{},{},it,extra,parents)::fs;
 
   end match;
 end setEnvName;

public function setParentEnv 
"set the name in the env"
  input Env inEnv;
  input Frame inFrame;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv,inFrame)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra extra;
      Env fs, env;
      Env parents;

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _)
      equation
        parents = inFrame::parents;
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs;
        
    case (FRAME(_,_,_,_,_,_,_,_,_,_)::_, _)
      equation
        print("Env.setParentEnv failed!\n");
      then
        fail();
  end matchcontinue;
end setParentEnv;

public function mergeEnv
"@author: adrpo
 in order to keep track of where we are 
 we merge environments when we switch scopes:
 We are in A.B.C we lookup X.Y.Z for component z
 -> merged env: COMPOSITE(A.B.C.z).X.Y.Z
 This way we can generate unique environments in which fully qualifying works."
  input Env inChildEnv;
  input Env inParentEnv;
  input Ident inName;
  input SCode.Element inChildClass;
  input Modification inMods;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inChildEnv, inParentEnv, inName, inChildClass, inMods)
    local
      Env c, p, eq;
      Ident name;
      Frame f, ftop;
      Absyn.Path path;

    // do not merge envs for MetaModelica
    case (_, _, _, _, _)
      equation
        // true = Config.acceptMetaModelicaGrammar();
      then
        inChildEnv;

    // merge
    case (_::_::_, _, _, _, _)
      equation
        false = stringEq(Absyn.pathFirstIdent(getEnvName(inParentEnv)), "OpenModelica");
        eq = envEqualPrefix(inChildEnv, inParentEnv);
        //print("Merging1CE: " +& getEnvNameStr(inChildEnv) +& "/" +& SCode.elementName(inChildClass) +& "\n" +& " with   PE: " +& getEnvNameStr(inParentEnv) +& "\n" +& " with   EL: " +& inName +& "\n");
        //print("Merging1EQ: " +& getEnvNameStr(eq) +& "\n");
        c = listReverse(inChildEnv);
        f = List.first(c);
        c = List.stripN(c, listLength(eq) + 1);
        //print("Merging1ST: " +& getEnvNameStr(listReverse(f::c)) +& "\n");
        c = setEnvName(f::c, SOME(inName));
        c = listReverse(c);
        c = listAppend(c, inParentEnv);
        //print("Merging1RE: " +& getEnvNameStr(c) +& "/" +& SCode.elementName(inChildClass) +& "\n");
      then
        c;

    // merge
    case (_::_, _, _, _, _)
      equation
        //print("Merging2CE: " +& getEnvNameStr(inChildEnv) +& "/" +& SCode.elementName(inChildClass) +& "\n" +& " with   PE: " +& getEnvNameStr(inParentEnv) +& "\n" +& " with   EL: " +& inName +& "\n");
        c = listReverse(inChildEnv);
        c = setEnvName(c, SOME(inName));
        c = listReverse(c);
        c = listAppend(c, inParentEnv);
        //print("Merging2RE: " +& getEnvNameStr(c) +& "/" +& SCode.elementName(inChildClass) +& "\n");
      then
        c;
        
    case (_, _, _, _, _)
      equation
        print("Merge fail CE: " +& getEnvNameStr(inChildEnv) +& "\n" +& 
              "           PE: " +& getEnvNameStr(inParentEnv) +& "\n" +& 
              " with element: " +& inName +& "\n");
      then
        inChildEnv; 

  end matchcontinue;
end mergeEnv;

public function splitEnv
"@author: adrpo
 in order to keep track of where we are 
 we merge environments when we switch scopes:
 We are in A.B.C we lookup X.Y.Z for component z
 -> merged env: A.B.C.z.X.Y.Z
 This way we can generate unique environments in which fully qualifying works."
  input Env inChildEnv;
  input Env inParentEnv;
  input Ident inName;
  output Env outChildEnv;
  output Env outParentEnv;
algorithm
  (outChildEnv, outParentEnv) := matchcontinue(inChildEnv, inParentEnv, inName)
    local
      Env c, p;
      Ident name;
      Integer len;

    // do not split envs for MetaModelica
    case (_, _, _)
      equation
        true = Config.acceptMetaModelicaGrammar();
      then
        (inChildEnv, inParentEnv);
    
    case (_, _, _)
      equation
        /*
        print("Split fail CE: " +& getEnvNameStr(inChildEnv) +& "\n" +& 
              "           PE: " +& getEnvNameStr(inParentEnv) +& "\n" +& 
              " with element: " +& inName +& "\n");*/
      then
        (inChildEnv, inParentEnv); 

  end matchcontinue;
end splitEnv;

public function getModifications
"returns the propagated modifers from the first frame"
  input Env inEnv;
  output Modifications outPMs;
algorithm
  outPMs := match(inEnv)
    local
      Modifications pm;

    // empty case
    case ({}) then {};

    case (FRAME(extra = EXTRA(mods = pm))::_) then pm;
  
  end match;
end getModifications;

public function addModifications 
"add the propagated modifers to the ones already in the env"
  input Env inEnv;
  input Modifications inPMs;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv,inPMs)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Modifications       mo;
      Env fs, parents;
      Integer             isCo;

    case (_, _)
      equation
        true = Config.acceptMetaModelicaGrammar(); 
      then inEnv;

    // empty case
    case ({}, _) then {};

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,EXTRA(mo,isCo),parents)::fs, _)
      equation
        // Cannot List.union stuff that contains arrays; need a comparison function
        // mo = List.union(inPMs, mo);
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,EXTRA(mo,isCo),parents)::fs;
  
  end matchcontinue;
end addModifications;

public function addModification 
"add the propagated modifers to the ones already in the env"
  input Env inEnv;
  input Modification inPM;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEnv,inPM)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Modifications       mo;
      Env fs, parents;
      Integer isCo;

    case (_, _)
      equation
        true = Config.acceptMetaModelicaGrammar(); 
      then inEnv;
   
    // empty case
    case ({}, _) then {};

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,EXTRA(mo,isCo),parents)::fs, _)
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,it,EXTRA(inPM::mo,isCo),parents)::fs;

  end matchcontinue;
end addModification;

public function hasModifications 
"searches the env for propagated modifers"
  input Env inEnv;
  output Boolean yes;
algorithm
  yes := matchcontinue(inEnv)
    local
      Modifications pm;
      Boolean b;
      Env fs;

    // empty case
    case ({}) then false;

    case (FRAME(extra = EXTRA(mods = pm))::_)
      equation
        true = hasModifications2(pm);
      then
        true;
    
    case (FRAME(extra = EXTRA(mods = pm))::fs)
      equation
        false = hasModifications2(pm);
        b = hasModifications(fs);
      then
        b;
  
  end matchcontinue;
end hasModifications;

public function hasModifications2 
"searches the env for propagated modifers"
  input Modifications inPM;
  output Boolean yes;
algorithm
  yes := matchcontinue(inPM)
    local
      Modifications rest;
      Boolean b;

    // empty case
    case ({}) then false;

    case (M(m = DAE.NOMOD())::rest)
      equation
        b = hasModifications2(rest);
      then
        b;

    case (M(m = DAE.MOD(subModLst={},eqModOption=NONE()))::rest)
      equation
        b = hasModifications2(rest);
      then
        b;
    
     else true;

  end matchcontinue;
end hasModifications2;

public function printModifications 
"searches the env for propagated modifers"
  input Env inEnv;
algorithm
  _ := match(inEnv)
    local
      Modifications pm;
      String str;
      Env fs;

    // empty case
    case ({}) then ();

    case (FRAME(extra = EXTRA(mods = pm))::fs)
      equation
        str = propagatedModifiersStr(pm);
        print("Env: " +& getEnvNameStr(inEnv) +& " modifiers: " +& str +& "\n");
        printModifications(fs);
      then
        ();
      
  end match;
end printModifications;

public function propagatedModifiersStr
"searches the env for propagated modifers"
  input Modifications inPM;
  output String outStr;
algorithm
  outStr := match(inPM)
    local
      Modifications rest;
      DAE.Mod m;
      Env env;
      String str;

    // empty case
    case ({}) then "";

    case (M(m = m, e = env)::rest)
      equation
        str = getEnvNameStr(env) +& "[" +& Mod.printModStr(m) +& "]";
        str = str +& " " +& propagatedModifiersStr(rest);
      then
        str;
    
  end match;
end propagatedModifiersStr;

public function extendFrameDefunit
"Adds a defineunit to the environment."
  input Env inEnv;
  input SCode.Element defunit;
  output Env outEnv;
algorithm
  outEnv := match (inEnv,defunit)
    local
      Option<Ident>       id;
      Option<ScopeType>   st;
      FrameType           ft;
      AvlTree             clsAndVars;
      AvlTree             tys;
      CSetsType           crs;
      list<SCode.Element> du;
      ImportTable         it;
      Extra               extra;
      Env fs, parents;

    case (FRAME(id,st,ft,clsAndVars,tys,crs,du,it,extra,parents)::fs, _)
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,defunit::du,it,extra,parents)::fs;

  end match;
end extendFrameDefunit;

public function extendFrameForIterator
"Adds a for loop iterator to the environment."
  input Env env;
  input String name;
  input DAE.Type ty;
  input DAE.Binding binding;
  input SCode.Variability variability;
  input Option<DAE.Const> constOfForIteratorRange;
  output Env outEnv;
algorithm
  outEnv := match(env, name, ty, binding, variability, constOfForIteratorRange)
    local
      Env new_env;

    case (_, _, _, _,_,_)
      equation
        new_env = pushFrameItem(
          env,
          name,
          VAR(
            DAE.TYPES_VAR(
              name,
              DAE.ATTR(SCode.POTENTIAL(), SCode.NON_PARALLEL(), variability, Absyn.BIDIR(), Absyn.NOT_INNER_OUTER(), SCode.PUBLIC()),
              ty,
              binding,
              constOfForIteratorRange),
            SCode.COMPONENT(
              name,
              SCode.defaultPrefixes,
              SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()),
              Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
              SCode.noComment, NONE(), Absyn.dummyInfo),
            DAE.NOMOD(),
            VAR_UNTYPED(),
            {},
            BUILTIN()
            ),
          {});
      then 
        new_env;

  end match;
end extendFrameForIterator;

public function topFrame "Returns the top frame."
  input Env inEnv;
  output Frame outFrame;
algorithm
  outFrame := match (inEnv)
    local
      Frame fr,elt;
      Env lst;
    case ({fr}) then fr;
    case ((_ :: (lst as (_ :: _))))
      equation
        fr = topFrame(lst);
      then
        fr;
  end match;
end topFrame;

public function getItemInEnv
"@author: adrpo
 returns the item found in the first frame in env or fails"
  input Absyn.Ident inName;
  input Env inEnv;
  output Item outItem;
protected
  AvlTree tree;
algorithm
  FRAME(clsAndVars = tree) :: _ := inEnv;
  outItem := avlTreeGet(tree, inName);
end getItemInEnv;

public function getClassName
  input Env inEnv;
  output Ident name;
algorithm
   name := match (inEnv)
     local Ident n;
     case FRAME(name = SOME(n))::_ then n;
  end match;
end getClassName;

public function getEnvName
"Returns the FQ name of the environment, see also getEnvPath"
  input Env inEnv;
  output Absyn.Path outPath;
protected
  Ident id;
  Env rest;
  Absyn.Path p;
algorithm
  // outPath := Absyn.makeFullyQualified(getEnvName_dispatch(inEnv));
  outPath :=  getEnvName_dispatch(inEnv);
end getEnvName;

protected function getEnvName_dispatch
"Returns the Q name of the environment, see also getEnvPath"
  input Env inEnv;
  output Absyn.Path outPath;
protected
  Ident id;
  Env rest;
  Absyn.Path p;
algorithm
  outPath := match (inEnv)
    case (FRAME(name = SOME(id)) :: rest)
      equation
        outPath = getEnvName2(rest, Absyn.IDENT(id));
      then 
        outPath;
  end match;
end getEnvName_dispatch;

public function getEnvName2
  input Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := match (inEnv, inPath)
    local
      Ident id;
      Env rest, env;
      Absyn.Path p;

    case (FRAME(name = SOME(id)) :: rest, _)
      then getEnvName2(rest, Absyn.QUALIFIED(id, inPath));
    
    else inPath;
  end match;
end getEnvName2;

public function getEnvPath "This function returns all partially instantiated parents as an Absyn.Path
  option I.e. it collects all identifiers of each frame until it reaches
  the topmost unnamed frame. If the environment is only the topmost frame,
  NONE() is returned."
  input Env inEnv;
  output Option<Absyn.Path> outEnvPath;
algorithm
  outEnvPath := matchcontinue(inEnv)
    local
      Absyn.Path path;

    case _
      equation
        path = getEnvName(inEnv);
      then
        SOME(path);

    else NONE();
  end matchcontinue;
end getEnvPath;

public function getEnvPathNoImplicitScope "This function returns all partially instantiated parents as an Absyn.Path
  option I.e. it collects all identifiers of each frame until it reaches
  the topmost unnamed frame. If the environment is only the topmost frame,
  NONE() is returned."
  input Env inEnv;
  output Option<Absyn.Path> outAbsynPathOption;
algorithm
  outAbsynPathOption := matchcontinue (inEnv)
    local
      Option<String> oid;
      Ident id;
      Absyn.Path path,path_1;
      Env rest;
    case ((FRAME(name = oid) :: rest))
      equation
        true = isImplicitScope(oid);
      then getEnvPathNoImplicitScope(rest);
    case ((FRAME(name = oid as SOME(id)) :: rest))
      equation
        false = isImplicitScope(oid);
        SOME(path) = getEnvPathNoImplicitScope(rest);
        path_1 = Absyn.joinPaths(path, Absyn.IDENT(id));
      then
        SOME(path_1);
    case (FRAME(name = oid as SOME(id))::rest)
      equation
        false = isImplicitScope(oid);
        NONE() = getEnvPathNoImplicitScope(rest);
      then SOME(Absyn.IDENT(id));
    case (_) then NONE();
  end matchcontinue;
end getEnvPathNoImplicitScope;

public function joinEnvPath "Used to join an Env with an Absyn.Path (probably an IDENT)"
  input Env inEnv;
  input Absyn.Path inPath;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inEnv,inPath)
    local
      Absyn.Path envPath;
    case (_,_)
      equation
        SOME(envPath) = getEnvPath(inEnv);
        //envPath = Absyn.makeFullyQualified(Absyn.joinPaths(envPath,inPath));
        envPath = Absyn.joinPaths(envPath,inPath);
      then envPath;
    case (_,_)
      equation
        NONE() = getEnvPath(inEnv);
      then inPath;
  end matchcontinue;
end joinEnvPath;

public function getEnvNameStr
  "Returns the FQ name of the environment, see also getEnvPath"
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue(inEnv)
    case (_)
      then
        Absyn.pathString(getEnvName(inEnv));
    else ".";
  end matchcontinue;
end getEnvNameStr;

public function printEnvPathStr " Retrive the environment path as a string, see getEnvPath."
  input Env inEnv;
  output String outString;
algorithm
  outString := matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
      then
        pathstr;
    case (_) then "<global scope>";
  end matchcontinue;
end printEnvPathStr;

public function printEnvPath "Print the environment path to the Print buffer.
  See also getEnvPath"
  input Env inEnv;
algorithm
  _ := matchcontinue (inEnv)
    local
      Absyn.Path path;
      Ident pathstr;
      Env env;
    case (env)
      equation
        SOME(path) = getEnvPath(env);
        pathstr = Absyn.pathString(path);
        Print.printBuf(pathstr);
      then
        ();
    case (_)
      equation
        Print.printBuf("TOPENV");
      then
        ();
  end matchcontinue;
end printEnvPath;

public function printEnvStr "Print the environment as a string."
  input Env inEnv;
  output String outString;
algorithm
  outString := match (inEnv)
    local
      Ident s1,s2,res;
      Frame fr;
      Env frs;
    case {} then "Empty env\n";
    case (fr :: frs)
      equation
        s1 = printFrameStr(fr);
        s2 = printEnvStr(frs);
        res = stringAppend(s1, s2);
      then
        res;
  end match;
end printEnvStr;

public function printEnv "Print the environment to the Print buffer."
  input Env e;
protected
  Ident s;
algorithm
  s := printEnvStr(e);
  Print.printBuf(s);
end printEnv;

public function printEnvConnectionCrefs "prints the connection crefs of the top frame"
  input Env env;
algorithm
  _ := match(env)
    local
      list<DAE.ComponentRef> crs;
      CSetsType clst;

    case (FRAME(connectionSet = clst)::_)
      equation
        crs = List.flatten(List.map(clst, Util.tuple21));
        print(printEnvPathStr(env));print(" :   ");
        print(stringDelimitList(List.map(crs,ComponentReference.printComponentRefStr),", "));
        print("\n");
      then ();
  end match;
end printEnvConnectionCrefs;

protected function printFrameStr "Print a Frame to a string."
  input Frame inFrame;
  output String outString;
algorithm
  outString := match (inFrame)
    local
      Ident s1,s2,frmTyStr,res,sid;
      Option<Ident> optName;
      AvlTree httypes;
      AvlTree ht;
      CSetsType crs;
      FrameType frameType;

    case FRAME(name = optName,
               clsAndVars = ht,
               types = httypes,
               connectionSet = _,
               frameType = frameType)
      equation
        sid = Util.getOptionOrDefault(optName, "unnamed");
        s1 = printAvlTreeStr(ht);
        s2 = printAvlTreeStr(httypes);
        frmTyStr = printFrameTypeStr(frameType);
        res = stringAppendList(
          "FRAME: " :: sid :: " (enc=" :: frmTyStr ::
          ") \nClasses and Vars:\n=============\n" ::
          s1 :: "\nTypes:\n======\n" :: s2 :: "\n" :: {});
      then
        res;
  end match;
end printFrameStr;

protected function printFrameVarsStr "Print only the variables in a Frame to a string."
  input Frame inFrame;
  output String outString;
algorithm
  outString := matchcontinue (inFrame)
    local
      Ident s1,frmTyStr,res,sid;
      AvlTree httypes;
      AvlTree ht;
      list<AvlValue> imps;
      CSetsType crs;
      FrameType frameType;
      Option<Ident> optName;

    case FRAME(name = optName,
               frameType = frameType,
               clsAndVars = ht,
               types = _,
               connectionSet = _)
      equation
        sid = Util.stringOption(optName);
        s1 = printAvlTreeStr(ht);
        frmTyStr = printFrameTypeStr(frameType);
        res = stringAppendList({"FRAME: ",sid," (frmTy=",frmTyStr,
                                ") \nclasses and vars:\n=============\n",
                                s1,"\n\n\n"});
      then
        res;

    case _ then "";

  end matchcontinue;
end printFrameVarsStr;

protected function printFrameTypeStr
  input FrameType inFrame;
  output String outString;
algorithm
  outString := match(inFrame)
    case NORMAL_SCOPE() then "Normal";
    case ENCAPSULATED_SCOPE() then "Encapsulated";
    case IMPLICIT_SCOPE(iterIndex=_) then "Implicit";
  end match;
end printFrameTypeStr;

protected function printImportsStr "Print import statements to a string."
  input list<Item> inItemLst;
  output String outString;
algorithm
  outString:=
  matchcontinue (inItemLst)
    local
      Ident s1,s2,res;
      AvlValue e;
      list<AvlValue> rst;
    case {} then "";
    case {e}
      equation
        s1 = printFrameElementStr(("",e));
      then
        s1;
    case ((e :: rst))
      equation
        s1 = printFrameElementStr(("",e));
        s2 = printImportsStr(rst);
        res = stringAppendList({s1,", ",s2});
      then
        res;
  end matchcontinue;
end printImportsStr;

protected function printFrameElementStr "Print frame element to a string"
  input tuple<Ident, Item> inTplIdentItem;
  output String outString;
algorithm
  outString := match (inTplIdentItem)
    local
      Ident s,elt_str,tp_str,var_str,frame_str,bind_str,res,n,lenstr;
      DAE.Var tv;
      SCode.Variability var;
      DAE.Type tp;
      DAE.Binding bind,bnd;
      SCode.Element elt;
      InstStatus i;
      Frame compframe;
      Env env;
      Integer len;
      list<DAE.Type> lst;
      Absyn.Import imp;

    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(variability = var),ty = tp,binding = bind)),var = elt,instStatus = _,env = (compframe :: _))))
      equation
        s = SCodeDump.variabilityString(var);
        elt_str = SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        frame_str = printFrameVarsStr(compframe);
        bind_str = Types.printBindingStr(bind);
        res = stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, binding:",bind_str});
      then
        res;

    case ((n,VAR(instantiated = (tv as DAE.TYPES_VAR(attributes = DAE.ATTR(variability = var),ty = tp)),var = elt,instStatus = _,env = {})))
      equation
        s = SCodeDump.variabilityString(var);
        elt_str = SCodeDump.unparseElementStr(elt,SCodeDump.defaultOptions);
        tp_str = Types.unparseType(tp);
        var_str = Types.unparseVar(tv);
        res = stringAppendList(
          {"v:",n," ",s,"(",elt_str,") [",tp_str,"] {",var_str,
          "}, compframe: []"});
      then
        res;

    case ((n,CLASS(cls = _)))
      equation
        res = stringAppendList({"c:",n,"\n"});
      then
        res;

    case ((n,TYPE(tys = lst)))
      equation
        len = listLength(lst);
        lenstr = intString(len);
        res = stringAppendList({"t:",n," (",lenstr,")\n"});
      then
        res;

    case ((_,_))
      equation
        res = stringAppendList({"oth\n"});
      then
        res;
  end match;
end printFrameElementStr;

public function getProgramFromCache
  input Cache inCache;
  output Absyn.Program program;
algorithm
  program := match(inCache)
    case NO_CACHE() then Absyn.dummyProgram;
    case CACHE(program = program) then program;
  end match;
end getProgramFromCache;

public function setProgramInCache 
  input Cache inCache;
  input Absyn.Program program;
  output Cache outCache;
algorithm
  outCache := match(inCache,program)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Absyn.Path p;
      Option<Env> oenv;

    case (CACHE(oenv,ef,ht,p,_),_) then CACHE(oenv,ef,ht,p,program);
    else inCache;
  end match;
end setProgramInCache;

public function getCachedInitialEnv "get the initial environment from the cache"
  input Cache cache;
  output Env env;
algorithm
  env := match(cache)
    case (CACHE(initialEnv=SOME(env))) then env;
  end match;
end getCachedInitialEnv;

public function setCachedInitialEnv "set the initial environment in the cache"
  input Cache inCache;
  input Env env;
  output Cache outCache;
algorithm
  outCache := match(inCache,env)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;

    case (CACHE(_,ef,ht,p,program),_) then CACHE(SOME(env),ef,ht,p,program);
    else inCache;
  end match;
end setCachedInitialEnv;

public function setCachedFunctionTree
  input Cache inCache;
  input DAE.FunctionTree inFunctions;
  output Cache outCache;
protected
  Option<Env> env;
  array<DAE.FunctionTree> ef;
  StructuralParameters ht;
  Absyn.Path p;
  Absyn.Program program;
algorithm
  outCache := match (inCache,inFunctions)
    case (CACHE(env, _, ht, p, program), _)
      equation
        ef = arrayCreate(1, inFunctions);
      then CACHE(env, ef, ht, p, program);
    else inCache;
  end match;
end setCachedFunctionTree;

public function printCacheStr
  input Cache cache;
  output String str;
algorithm
  str := matchcontinue(cache)
    local
      array<DAE.FunctionTree> ef;
      String s;

    // some cache present
    case CACHE(functions=ef)
      equation
        s = DAEDump.dumpFunctionNamesStr(arrayGet(ef,1));
        str = "Instantiated funcs: " +& s +&"\n";
      then str;
    
    // empty cache
    else "EMPTY CACHE\n";
  
  end matchcontinue;
end printCacheStr;

/* AVL impementation */
public type AvlKey = String;
public type AvlValue = Item;

public function keyStr "prints a key to a string"
input AvlKey k;
output String str;
algorithm
  str := k;
end keyStr;

protected function printElement
  input SCode.Element el;
  output String str;
algorithm
  str := match(el)
    case (_) then "[el:" +& SCodeDump.unparseElementStr(el,SCodeDump.defaultOptions) +& "], ";
  end match;
end printElement;

protected function printInstStatus
  input InstStatus instStatus;
  output String str;
algorithm
  str := match(instStatus)
    case (VAR_UNTYPED()) then "inst: var untyped";
    case (VAR_TYPED())   then "inst: var typed";
    case (VAR_DAE())     then "inst: var dae";
  end match;
end printInstStatus;

public function valueStr "prints a Value to a string"
  input AvlValue v;
  output String str;
algorithm
  str := match(v)
    local
      String name;
      DAE.Type tp;
      SCode.ConnectorType ct;
      SCode.Parallelism parallelism;
      SCode.Variability variability "variability";
      Absyn.Direction direction "direction";
      Absyn.InnerOuter innerOuter "inner, outer,  inner outer or unspecified";
      SCode.Element el;
      InstStatus instStatus;
      String s1, s2, s3, s4, s5;
      DAE.Binding binding;
      SCode.Element e;
      Env env;


    case(VAR(instantiated=DAE.TYPES_VAR(name=name,attributes=DAE.ATTR(ct, parallelism, variability, direction, innerOuter, _),ty=tp,binding=binding),
             var = el, instStatus=instStatus, env = env))
      equation
        s1 = SCodeDump.connectorTypeStr(ct);
        s1 = Util.if_(stringEq(s1, ""), "", s1 +& ", ");
        s2 = SCodeDump.parallelismString(parallelism);
        s2 = Util.if_(stringEq(s2, ""), "", s2 +& ", ");
        s3 = SCodeDump.variabilityString(variability);
        s3 = Util.if_(stringEq(s3, ""), "", s3 +& ", ");
        s4 = Dump.unparseDirectionSymbolStr(direction);
        s4 = Util.if_(stringEq(s4, ""), "", s4 +& ", ");
        s5 = SCodeDump.innerouterString(innerOuter);
        s5 = Util.if_(stringEq(s5, ""), "", s5 +& ", ");

        str = "var:    " +& name +& " " +& Types.unparseType(tp) +& "("
        +& Types.printTypeStr(tp) +& ") binding: " +& Types.printBindingStr(binding) +& " attr: " +& s1 +& s2 +& s3 +& s4 +& s5 +&
        printElement(el) +& printInstStatus(instStatus) +& " env: " +& printEnvPathStr(env);
      then str;

    case(CLASS(cls = e as SCode.CLASS(name=name), env = env))
      equation
        str = "class: " +& SCodeDump.shortElementStr(e) +& " env: " +& printEnvPathStr(env);
      then str;

    case(TYPE(tp::_))
      equation
        str = "type:   " +& Types.unparseType(tp);
      then str;

  end match;
end valueStr;

/* Generic Code below */
public
uniontype AvlTree "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value" ;
    Integer height "heigth of tree, used for balancing";
    Option<AvlTree> left "left subtree" ;
    Option<AvlTree> right "right subtree" ;
  end AVLTREENODE;
end AvlTree;

public
uniontype AvlTreeValue "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

public constant AvlTree emptyAvlTree = AVLTREENODE(NONE(),0,NONE(),NONE());

public function avlTreeNew "Return an empty tree"
  output AvlTree tree;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  tree := emptyAvlTree;
end avlTreeNew;

public function avlTreeAdd
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;

    // empty tree
    case (AVLTREENODE(value = NONE(),left = NONE(),right = NONE()),key,value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key,value)),1,NONE(),NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey))),key,value)
      then balance(avlTreeAdd2(inAvlTree,stringCompare(key,rkey),key,value));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAdd failed"});
      then fail();
  end match;
end avlTreeAdd;

public function avlTreeAdd2
  "Help function to avlTreeAdd."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match (inAvlTree,keyComp,inKey,inValue)
    local
      AvlKey key,rkey;
      AvlValue value;
      Option<AvlTree> left,right;
      Integer h;
      AvlTree t_1,t;
      Option<AvlTreeValue> oval;

    /*/ Don't allow replacing of nodes.
    case (_, 0, key, _)
      equation
        info = getItemInfo(inValue);
        Error.addSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
          {inKey}, info);
      then
        fail();*/

    // replace this node
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey)),height=h,left = left,right = right),0,key,value)
      equation
        // inactive for now, but we should check if we don't replace a class with a var or vice-versa!
        // checkValueReplacementCompatible(rval, value);
      then
        AVLTREENODE(SOME(AVLTREEVALUE(rkey,value)),h,left,right);

    // insert to right
    case (AVLTREENODE(value = oval,height=h,left = left,right = right),1,key,value)
      equation
        t = createEmptyAvlIfNone(right);
        t_1 = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval,h,left,SOME(t_1));

    // insert to left subtree
    case (AVLTREENODE(value = oval,height=h,left = left ,right = right),-1,key,value)
      equation
        t = createEmptyAvlIfNone(left);
        t_1 = avlTreeAdd(t, key, value);
      then
        AVLTREENODE(oval,h,SOME(t_1),right);

  end match;
end avlTreeAdd2;

protected function checkValueReplacementCompatible
"@author: adrpo 2010-10-07
  This function checks if what we replace in the environment
  is compatible with the value we want to replace with.
  VAR<->VAR OK
  CLASS<->CLASS OK
  TYPE<->TYPE OK
  All the other replacements will output a warning!"
  input AvlValue val1;
  input AvlValue val2;
algorithm
  _ := match(val1, val2)
    local
      Absyn.Info aInfo;
      String n1, n2;

    // var can replace var
    case (VAR(instantiated = _), VAR(instantiated = _)) then ();
    // class can replace class
    case (CLASS(cls = _),     CLASS(cls = _)) then ();
    // type can replace type
    case (TYPE(tys = _),       TYPE(tys = _)) then ();
    // anything else is an error!
    else
      equation
        (n1, n2, aInfo) = getNamesAndInfoFromVal(val1, val2);
        Error.addSourceMessage(Error.COMPONENT_NAME_SAME_AS_TYPE_NAME, {n1,n2}, aInfo);
      then
        ();
  end match;
end checkValueReplacementCompatible;

protected function getNamesAndInfoFromVal
  input AvlValue val1;
  input AvlValue val2;
  output String name1;
  output String name2;
  output Absyn.Info info;
algorithm
  (name1, name2, info) := matchcontinue(val1, val2)
    local
      Absyn.Info aInfo;
      String n1, n2, n;
      Env env;

    // var should not be replaced by class!
    case (VAR(var = SCode.COMPONENT(name = n1, info = aInfo)),
          CLASS(cls = SCode.CLASS(name = n2, info = _), env = env))
      equation
         n = printEnvPathStr(env);
         n2 = n +& "." +& n2;
      then
        (n1, n2, aInfo);

    // class should not be replaced by var!
    case (CLASS(cls = _), VAR(instantiated = _))
      equation
        // call ourselfs reversed
        (n1, n2, aInfo) = getNamesAndInfoFromVal(val2, val1);
      then
        (n1, n2, aInfo);

    // anything else that might happen??
    else
      equation
        n1 = valueStr(val1);
        n2 = valueStr(val2);
      then
        (n1, n2, Absyn.dummyInfo);
  end matchcontinue;
end getNamesAndInfoFromVal;

protected function createEmptyAvlIfNone "Help function to AvlTreeAdd2"
  input Option<AvlTree> t;
  output AvlTree outT;
algorithm
  outT := match (t)
    case(NONE()) then AVLTREENODE(NONE(),0,NONE(),NONE());
    case(SOME(outT)) then outT;
  end match;
end createEmptyAvlIfNone;

protected function nodeValue "return the node value"
  input AvlTree bt;
  output AvlValue v;
algorithm
  v := match (bt)
    case(AVLTREENODE(value=SOME(AVLTREEVALUE(_,v)))) then v;
  end match;
end nodeValue;

protected function balance "Balances a AvlTree"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (inBt)
    local Integer d; AvlTree bt;
    case (bt)
      equation
        d = differenceInHeight(bt);
        bt = doBalance(d,bt);
      then bt;
  end match;
end balance;

protected function doBalance "perform balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (difference,inBt)
    local AvlTree bt;
    case(-1,bt) then computeHeight(bt);
    case(0,bt) then computeHeight(bt);
    case(1,bt) then computeHeight(bt);
      /* d < -1 or d > 1 */
    case(_,bt)
      equation
        bt = doBalance2(difference < 0,bt);
      then bt;
  end match;
end doBalance;

protected function doBalance2 "help function to doBalance"
  input Boolean differenceIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match (differenceIsNegative,inBt)
    local AvlTree bt;
    case (true,bt)
      equation
        bt = doBalance3(bt);
        bt = rotateLeft(bt);
      then bt;
    case (false,bt)
      equation
        bt = doBalance4(bt);
        bt = rotateRight(bt);
      then bt;
  end match;
end doBalance2;

protected function doBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
        true = differenceInHeight(getOption(rightNode(bt))) > 0;
        rr = rotateRight(getOption(rightNode(bt)));
        bt = setRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance3;

protected function doBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
        true = differenceInHeight(getOption(leftNode(bt))) < 0;
        rl = rotateLeft(getOption(leftNode(bt)));
        bt = setLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end doBalance4;

protected function setRight "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
algorithm
  outNode := match (node,right)
   local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,l,_),_) then AVLTREENODE(value,height,l,right);
  end match;
end setRight;

protected function setLeft "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
algorithm
  outNode := match (node,left)
  local Option<AvlTreeValue> value;
    Option<AvlTree> l,r;
    Integer height;
    case(AVLTREENODE(value,height,_,r),_) then AVLTREENODE(value,height,left,r);
  end match;
end setLeft;

protected function leftNode "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(AVLTREENODE(left = subNode)) then subNode;
  end match;
end leftNode;

protected function rightNode "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  subNode := match(node)
    case(AVLTREENODE(right = subNode)) then subNode;
  end match;
end rightNode;

protected function exchangeLeft "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inNode,inParent)
    local
      AvlTree bt,node,parent;

    case(node,parent) equation
      parent = setRight(parent,leftNode(node));
      parent = balance(parent);
      node = setLeft(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeLeft;

protected function exchangeRight "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
algorithm
  outParent := match(inNode,inParent)
  local AvlTree bt,node,parent;
    case(node,parent) equation
      parent = setLeft(parent,rightNode(node));
      parent = balance(parent);
      node = setRight(node,SOME(parent));
      bt = balance(node);
    then bt;
  end match;
end exchangeRight;

protected function rotateLeft "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeLeft(getOption(rightNode(node)),node);
end rotateLeft;

protected function getOption "Retrieve the value of an option"
  replaceable type T subtypeof Any;
  input Option<T> opt;
  output T val;
algorithm
  val := match(opt)
    case(SOME(val)) then val;
  end match;
end getOption;

protected function rotateRight "help function to balance"
input AvlTree node;
output AvlTree outNode "updated node";
algorithm
  outNode := exchangeRight(getOption(leftNode(node)),node);
end rotateRight;

protected function differenceInHeight "help function to balance, calculates the difference in height
between left and right child"
  input AvlTree node;
  output Integer diff;
algorithm
  diff := match (node)
    local
      Integer lh,rh;
      Option<AvlTree> l,r;
    case(AVLTREENODE(left=l,right=r))
      equation
        lh = getHeight(l);
        rh = getHeight(r);
      then lh - rh;
  end match;
end differenceInHeight;

public function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,inKey)
    local
      AvlKey rkey,key;
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key=rkey))),key)
      then avlTreeGet2(inAvlTree,stringCompare(key,rkey),key);
  end match;
end avlTreeGet;

protected function avlTreeGet2
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input Integer keyComp "0=get value from current node, 1=search right subtree, -1=search left subtree";
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match (inAvlTree,keyComp,inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left,right;

    // hash func Search to the right
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value=rval))),0,_)
      then rval;

    // search to the right
    case (AVLTREENODE(right = SOME(right)),1,key)
      then avlTreeGet(right, key);

    // search to the left
    case (AVLTREENODE(left = SOME(left)),-1,key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function getOptionStr "Retrieve the string from a string option.
  If NONE() return empty string."
  input Option<Type_a> inTypeAOption;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  output String outString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm
  outString:=
  match (inTypeAOption,inFuncTypeTypeAToString)
    local
      String str;
      Type_a a;
      FuncTypeType_aToString r;
    case (SOME(a),r)
      equation
        str = r(a);
      then
        str;
    case (NONE(),_) then "";
  end match;
end getOptionStr;

protected function printAvlTreeStr "
  Prints the avl tree to a string"
  input AvlTree inAvlTree;
  output String outString;
algorithm
  outString:=
  match (inAvlTree)
    local
      AvlKey rkey;
      String s2,s3,res;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(_,rval)),height = _,left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = "\n" +& valueStr(rval) +& ",  " +& Util.if_(stringEq(s2, ""), "", s2 +& ", ") +& s3;
      then
        res;
    case (AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        s2 = getOptionStr(l, printAvlTreeStr);
        s3 = getOptionStr(r, printAvlTreeStr);
        res = Util.if_(stringEq(s2, ""), "", s2 +& ", ") +& s3;
      then
        res;
  end match;
end printAvlTreeStr;

protected function computeHeight "compute the heigth of the AvlTree and store in the node info"
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(bt)
    local
      Option<AvlTree> l,r;
      Option<AvlTreeValue> v;
      Integer hl,hr,height;
    case(AVLTREENODE(value=v as SOME(_),left=l,right=r))
      equation
        hl = getHeight(l);
        hr = getHeight(r);
        height = intMax(hl,hr) + 1;
      then AVLTREENODE(v,height,l,r);
  end match;
end computeHeight;

protected function getHeight "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match (bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end getHeight;

public function isTopScope "Returns true if we are in the top-most scope"
  input Env env;
  output Boolean isTop;
algorithm
  isTop := matchcontinue env
    case {FRAME(name = NONE())} then true;
    case _ then false;
  end matchcontinue;
end isTopScope;

public function getVariablesFromEnv
"@author: adrpo
  returns the a list with all the variables in the given environment"
  input Env inEnv;
  output list<String> variables;
algorithm
  variables := match (inEnv)
    local
      list<Ident> lst1;
      Frame fr;
      Env frs;
    // empty case
    case {} then {};
    // some environment
    case (fr :: _)
      equation
        lst1 = getVariablesFromFrame(fr);
        // adrpo: TODO! FIXME! CHECK if we really don't need this!
        // lst2 = getVariablesFromEnv(frs);
        // lst = listAppend(lst1, lst2);
      then
        lst1;
  end match;
end getVariablesFromEnv;

protected function getVariablesFromFrame
"@author: adrpo
  returns all variables in the frame as a list of strings."
  input Frame inFrame;
  output list<String> variables;
algorithm
  variables := match (inFrame)
    local
      list<Ident> lst;
      AvlTree ht;

    case FRAME(clsAndVars = ht)
      equation
        lst = getVariablesFromAvlTree(ht);
      then
        lst;
  end match;
end getVariablesFromFrame;

protected function getVariablesFromAvlTree
"@author: adrpo
  returns variables from the avl tree as a list of strings"
  input AvlTree inAvlTree;
  output list<String> variables;
algorithm
  variables := match (inAvlTree)
    local
      AvlKey rkey;
      list<String> lst0, lst1, lst2, lst;
      AvlValue rval;
      Option<AvlTree> l,r;
      Integer h;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(_,rval)),height = _,left = l,right = r))
      equation
        lst0 = getVariablesFromAvlValue(rval);
        lst1 = getVariablesFromOptionAvlTree(l);
        lst2 = getVariablesFromOptionAvlTree(r);
        lst = listAppend(lst1, lst2);
        lst = listAppend(lst0, lst);
      then
        lst;

    case (AVLTREENODE(value = NONE(),left = l,right = r))
      equation
        lst1 = getVariablesFromOptionAvlTree(l);
        lst2 = getVariablesFromOptionAvlTree(r);
        lst = listAppend(lst1, lst2);
      then
        lst;
  end match;
end getVariablesFromAvlTree;

protected function getVariablesFromOptionAvlTree
"@author: adrpo
  returns the variables from the given optional tree as a list of strings.
  if the tree is none then the function returns an empty list"
  input Option<AvlTree> inAvlTreeOpt;
  output list<String> variables;
algorithm
  variables := match (inAvlTreeOpt)
    local
      AvlTree avl;
    // handle nothingness
    case (NONE()) then {};
    // we have some value
    case (SOME(avl)) then getVariablesFromAvlTree(avl);
  end match;
end getVariablesFromOptionAvlTree;

public function getVariablesFromAvlValue
"@author:adrpo
  returns a list with one variable or an empty list"
  input AvlValue v;
  output list<String> variables;
algorithm
  variables := matchcontinue(v)
    local
      String name;
    case(VAR(instantiated=DAE.TYPES_VAR(name=name))) then {name};
    case(_) then {};
  end matchcontinue;
end getVariablesFromAvlValue;

public function inFunctionScope
  input Env inEnv;
  output Boolean inFunction;
algorithm
  inFunction := matchcontinue(inEnv)
    local
      list<Frame> fl;
    case ({}) then false;
    case (FRAME(scopeType = SOME(FUNCTION_SCOPE())) :: _) then true;
    case (FRAME(scopeType = SOME(PARALLEL_SCOPE())) :: _) then true;
    case (FRAME(scopeType = SOME(CLASS_SCOPE())) :: _) then false;
    case (_ :: fl) then inFunctionScope(fl);
  end matchcontinue;
end inFunctionScope;

public function classInfToScopeType
  input ClassInf.State inState;
  output Option<ScopeType> outType;
algorithm
  outType := matchcontinue(inState)
    case ClassInf.FUNCTION(path = _) then SOME(FUNCTION_SCOPE());
    case _ then SOME(CLASS_SCOPE());
  end matchcontinue;
end classInfToScopeType;

public function restrictionToScopeType
  input SCode.Restriction inRestriction;
  output Option<ScopeType> outType;
algorithm
  outType := matchcontinue(inRestriction)
    case SCode.R_FUNCTION(SCode.FR_PARALLEL_FUNCTION()) then SOME(PARALLEL_SCOPE());
    case SCode.R_FUNCTION(SCode.FR_KERNEL_FUNCTION()) then SOME(PARALLEL_SCOPE());
    case SCode.R_FUNCTION(_) then SOME(FUNCTION_SCOPE());
    case _ then SOME(CLASS_SCOPE());
  end matchcontinue;
end restrictionToScopeType;

public function getFunctionTree
"Selector function"
  input Cache cache;
  output DAE.FunctionTree ft;
algorithm
  ft := match cache
    local
      array<DAE.FunctionTree> ef;
    case CACHE(functions = ef) then arrayGet(ef, 1);
    else DAE.emptyFuncTree;
  end match;
end getFunctionTree;

public function addCachedInstFuncGuard
"adds the FQ path to the set of instantiated functions as NONE().
This guards against recursive functions."
  input Cache cache;
  input Absyn.Path func "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := matchcontinue(cache,func)
    local
      array<DAE.FunctionTree> ef;
      Option<Env> ienv;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;
    
    // Don't overwrite SOME() with NONE()
    case (_, _)
      equation
        checkCachedInstFuncGuard(cache, func);
      then cache;

    case (CACHE(ienv,ef,ht,p,program),Absyn.FULLYQUALIFIED(_))
      equation
        ef = arrayUpdate(ef,1,DAEUtil.avlTreeAdd(arrayGet(ef, 1),func,NONE()));
      then CACHE(ienv,ef,ht,p,program);
    
    // Non-FQ paths mean aliased functions; do not add these to the cache
    case (_,_) then (cache);
  
  end matchcontinue;
end addCachedInstFuncGuard;

public function addDaeFunction
"adds the list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
      array<DAE.FunctionTree> ef;
      Option<Env> ienv;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;
    
    case (CACHE(ienv,ef,ht,p,program),_)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeFunction(funcs, arrayGet(ef, 1)));
      then CACHE(ienv,ef,ht,p,program);
    else inCache;
  
  end match;
end addDaeFunction;

public function addDaeExtFunction
"adds the external functions in list<DAE.Function> to the set of instantiated functions"
  input Cache inCache;
  input list<DAE.Function> funcs "fully qualified function name";
  output Cache outCache;
algorithm
  outCache := match(inCache,funcs)
    local
      array<DAE.FunctionTree> ef;
      Option<Env> ienv;
      StructuralParameters ht;
      Absyn.Path p;
      Absyn.Program program;
    
    case (CACHE(ienv,ef,ht,p,program),_)
      equation
        ef = arrayUpdate(ef,1,DAEUtil.addDaeExtFunction(funcs, arrayGet(ef,1)));
      then CACHE(ienv,ef,ht,p,program);
    else inCache;
  
  end match;
end addDaeExtFunction;

public function getCachedInstFunc
"returns the function in the set"
  input Cache inCache;
  input Absyn.Path path;
  output DAE.Function func;
algorithm
  func := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),_)
      equation
        SOME(func) = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
      then func;
  end match;
end getCachedInstFunc;

public function checkCachedInstFuncGuard
"succeeds if the FQ function is in the set of functions"
  input Cache inCache;
  input Absyn.Path path;
algorithm
  _ := match(inCache,path)
    local
      array<DAE.FunctionTree> ef;
    case(CACHE(functions=ef),_) equation
      _ = DAEUtil.avlTreeGet(arrayGet(ef,1),path);
    then ();
  end match;
end checkCachedInstFuncGuard;

public function printAvlTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := printAvlTreeStrPP2(SOME(inTree), "");
end printAvlTreeStrPP;

protected function printAvlTreeStrPP2
  input Option<AvlTree> inTree;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inIndent)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      String s1, s2, res, indent;

    case (NONE(), _) then "";

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" +& inIndent +& rkey +& s1 +& s2;
      then
        res;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
        indent = inIndent +& "  ";
        s1 = printAvlTreeStrPP2(l, indent);
        s2 = printAvlTreeStrPP2(r, indent);
        res = "\n" +& s1 +& s2;
      then
        res;
  end match;
end printAvlTreeStrPP2;

public function addEvaluatedCref
  input Cache cache;
  input SCode.Variability var;
  input DAE.ComponentRef cr;
  output Cache ocache;
algorithm
  ocache := match (cache,var,cr)
    local
      Option<Env> initialEnv;
      array<DAE.FunctionTree> functions;
      HashTable.HashTable ht;
      list<list<DAE.ComponentRef>> st;
      list<DAE.ComponentRef> crs;
      Absyn.Path p;
      Absyn.Program program;
    
    case (CACHE(initialEnv,functions,(ht,crs::st),p,program),SCode.PARAM(),_)
      then CACHE(initialEnv,functions,(ht,(cr::crs)::st),p,program);
    
    else cache;
  
  end match;
end addEvaluatedCref;

public function getEvaluatedParams
  input Cache cache;
  output HashTable.HashTable ht;
algorithm
  CACHE(evaluatedParams=(ht,_)) := cache;
end getEvaluatedParams;

public function printNumStructuralParameters
  input Cache cache;
protected
  list<DAE.ComponentRef> crs;
algorithm
  CACHE(evaluatedParams=(_,crs::_)) := cache;
  print("printNumStructuralParameters: " +& intString(listLength(crs)) +& "\n");
end printNumStructuralParameters;

public function setCacheClassName
  input Cache inCache;
  input Absyn.Path p;
  output Cache outCache;
algorithm
  outCache := match(inCache,p)
    local
      array<DAE.FunctionTree> ef;
      StructuralParameters ht;
      Option<Env> ienv;
      Absyn.Program program;

    case (CACHE(ienv,ef,ht,_,program),_)
      then CACHE(ienv,ef,ht,p,program);
    else inCache;
  end match;
end setCacheClassName;

public function avlTreeReplace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, stringCompare(key, rkey), key, value);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeReplace failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (AVLTREENODE(value = SOME(_), height = h, left = left, right = right),
        0, key, value)
      then AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        1, key, value)
      equation
        t = createEmptyAvlIfNone(right);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
        -1, key, value)
      equation
        t = createEmptyAvlIfNone(left);
        t = avlTreeReplace(t, key, value);
      then
        AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeReplace2;

public function getClassesInFrame
  input Frame fr;
  output list<SCode.Element> elts;
protected
  AvlTree ht;
  list<AvlTreeValue> vals;
algorithm
  FRAME(clsAndVars=ht) := fr;
  vals := getAvlTreeItems(SOME(ht)::{},{});
  elts := List.fold(vals,getClassesFromItem,{});
end getClassesInFrame;

protected function getClassesFromItem
  input AvlTreeValue v;
  input list<SCode.Element> acc;
  output list<SCode.Element> res;
algorithm
  res := match (v,acc)
    local
      SCode.Element c;
    case (AVLTREEVALUE(value=CLASS(cls=c)),_) then c::acc;
    else acc;
  end match;
end getClassesFromItem;

protected function getAvlTreeItems
  input list<Option<AvlTree>> tree;
  input list<AvlTreeValue> acc;
  output list<AvlTreeValue> res;
algorithm
  res := match (tree,acc)
    local
      Option<AvlTreeValue> value;
      Option<AvlTree> left,right;
      list<Option<AvlTree>> rest;
    case ({},_) then acc;
    case (SOME(AVLTREENODE(value=value,left=left,right=right))::rest,_)
      then getAvlTreeItems(left::right::rest,List.consOption(value,acc));
    case (NONE()::rest,_) then getAvlTreeItems(rest,acc);
  end match;
end getAvlTreeItems;


// from FEnv.
protected function checkUniqueQualifiedImport
  "Checks that a qualified import is unique, because it's not allowed to have
  qualified imports with the same name."
  input Import inImport;
  input list<Import> inImports;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inImport, inImports, inInfo)
    local
      Absyn.Ident name;

    case (_, _, _)
      equation
        false = List.isMemberOnTrue(inImport, inImports,
          compareQualifiedImportNames);
      then
        ();

    case (Absyn.NAMED_IMPORT(name = name), _, _)
      equation
        Error.addSourceMessage(Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,
          {name}, inInfo);
      then
        fail();

  end matchcontinue;
end checkUniqueQualifiedImport;

protected function compareQualifiedImportNames
  "Compares two qualified imports, returning true if they have the same import
  name, otherwise false."
  input Import inImport1;
  input Import inImport2;
  output Boolean outEqual;
algorithm
  outEqual := matchcontinue(inImport1, inImport2)
    local
      Absyn.Ident name1, name2;

    case (Absyn.NAMED_IMPORT(name = name1), Absyn.NAMED_IMPORT(name = name2))
      equation
        true = stringEqual(name1, name2);
      then
        true;

    else then false;
  end matchcontinue;
end compareQualifiedImportNames;

public function extendEnvWithImport
  "Extends the environment with an import element."
  input SCode.Element inImport;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inImport, inEnv)
    local
      Option<Ident> id;
      Option<ScopeType> st;
      FrameType ft;
      AvlTree clsAndVars,tys;
      CSetsType crs;
      list<SCode.Element> du;
      Env rest;
      Import imp;
      list<Import> qual_imps, unqual_imps;
      Absyn.Info info;
      Boolean hidden;
      Extra extra;
      Env parents;

    // Unqualified imports
    case (SCode.IMPORT(imp = imp as Absyn.UNQUAL_IMPORT(path = _)),
          FRAME(id,st,ft,clsAndVars,tys,crs,du,
            IMPORT_TABLE(hidden, qual_imps, unqual_imps),
            extra, parents) :: rest)
      equation
        unqual_imps = imp :: unqual_imps;
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), extra, parents) :: rest;

    // Qualified imports
    case (SCode.IMPORT(imp = imp, info = info),
          FRAME(id,st,ft,clsAndVars,tys,crs,du,
            IMPORT_TABLE(hidden, qual_imps, unqual_imps),
            extra, parents) :: rest)
      equation
        imp = translateQualifiedImportToNamed(imp);
        checkUniqueQualifiedImport(imp, qual_imps, info);
        qual_imps = imp :: qual_imps;
      then
        FRAME(id,st,ft,clsAndVars,tys,crs,du,
          IMPORT_TABLE(hidden, qual_imps, unqual_imps), extra, parents) :: rest;
  end match;
end extendEnvWithImport;

protected function translateQualifiedImportToNamed
  "Translates a qualified import to a named import."
  input Import inImport;
  output Import outImport;
algorithm
  outImport := match(inImport)
    local
      Absyn.Ident name;
      Absyn.Path path;

    // Already named.
    case Absyn.NAMED_IMPORT(name = _) then inImport;

    // Get the last identifier from the import and use that as the name.
    case Absyn.QUAL_IMPORT(path = path)
      equation
        name = Absyn.pathLastIdent(path);
      then
        Absyn.NAMED_IMPORT(name, path);
  end match;
end translateQualifiedImportToNamed;

public function checkSameRestriction
"check if the restrictions are the same for redeclared classes"
  input SCode.Restriction inResNew;
  input SCode.Restriction inResOrig;
  input Absyn.Info inInfoNew;
  input Absyn.Info inInfoOrig;
  output SCode.Restriction outRes;
  output Absyn.Info outInfo;
algorithm
  (outRes, outInfo) := match(inResNew, inResOrig, inInfoNew, inInfoOrig)
    case (_, _, _, _)
      equation
        // todo: check if the restrictions are the same for redeclared classes
      then
        (inResNew, inInfoNew);
  end match;
end checkSameRestriction;

public function crefStripEnvPrefix
  "Removes the entire environment prefix from the given component reference, or
  returns the unchanged reference. This is done because models might import
  local packages, for example:

    package P
      import myP = InsideP;

      package InsideP
        function f end f;
      end InsideP;

      constant c = InsideP.f();
    end P;

    package P2
      extends P;
    end P2;

  When P2 is instantiated all elements from P will be brought into P2's scope
  due to the extends. The binding of c will still point to P.InsideP.f though, so
  the lookup will try to instantiate P which might fail if P is a partial
  package or for other reasons. This is really a bug in Lookup (it shouldn't
  need to instantiate the whole package just to find a function), but to work
  around this problem for now this function will remove the environment prefix
  when InsideP.f is looked up in P, so that it resolves to InsideP.f and not
  P.InsideP.f. This allows P2 to find it in the local scope instead, since the
  InsideP package has been inherited from P."
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  input Boolean stripPartial;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, stripPartial)
    local
      Absyn.Path env_path;
      Absyn.ComponentRef cref1, cref2;

    case (_, _, _)
      equation
        SOME(env_path) = getEnvPath(inEnv);
        cref1 = Absyn.unqualifyCref(inCref);
        env_path = Absyn.makeNotFullyQualified(env_path);
        // try to strip as much as possible
        cref2 = crefStripEnvPrefix2(cref1, env_path, stripPartial);
        // check if we really did anything, fail if we did nothing!
        false = Absyn.crefEqual(cref1, cref2);
      then
        cref2;

    else inCref;
  end matchcontinue;
end crefStripEnvPrefix;

protected function crefStripEnvPrefix2
  input Absyn.ComponentRef inCref;
  input Absyn.Path inEnvPath;
  input Boolean stripPartial;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnvPath, stripPartial)
    local
      Absyn.Ident id1, id2;
      Absyn.ComponentRef cref;
      Absyn.Path env_path;

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref),
          Absyn.QUALIFIED(name = id2, path = env_path), _)
      equation
        true = stringEqual(id1, id2);
      then
        crefStripEnvPrefix2(cref, env_path, stripPartial);

    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = cref),
          Absyn.IDENT(name = id2), _)
      equation
        true = stringEqual(id1, id2);
      then
        cref;
    
    // adrpo: leave it as stripped as you can if you can't match it above and we have true for stripPartial
    case (Absyn.CREF_QUAL(name = id1, subscripts = {}, componentRef = _),
          env_path, true)
      equation
        false = stringEqual(id1, Absyn.pathFirstIdent(env_path));
      then
        inCref;
  end matchcontinue;
end crefStripEnvPrefix2;

public function pathStripEnvPrefix
"same as pathStripEnvPrefix"
  input Absyn.Path inPath;
  input Env inEnv;
  input Boolean stripPartial;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnv, stripPartial)
    local
      Absyn.Path env_path;
      Absyn.Path path1, path2;

    case (_, _, _)
      equation
        SOME(env_path) = getEnvPath(inEnv);
        path1 = Absyn.makeNotFullyQualified(inPath);
        env_path = Absyn.makeNotFullyQualified(env_path);
        // try to strip as much as possible
        path2 = pathStripEnvPrefix2(path1, env_path, stripPartial);
        // check if we really did anything, fail if we did nothing!
        false = Absyn.pathEqual(path1, path2);
      then
        path2;

    else inPath;
  end matchcontinue;
end pathStripEnvPrefix;

protected function pathStripEnvPrefix2
  input Absyn.Path inPath;
  input Absyn.Path inEnvPath;
  input Boolean stripPartial;
  output Absyn.Path outPath;
algorithm
  outPath := matchcontinue(inPath, inEnvPath, stripPartial)
    local
      Absyn.Ident id1, id2;
      Absyn.Path path;
      Absyn.Path env_path;

    case (Absyn.QUALIFIED(name = id1, path = path),
          Absyn.QUALIFIED(name = id2, path = env_path), _)
      equation
        true = stringEqual(id1, id2);
      then
        pathStripEnvPrefix2(path, env_path, stripPartial);

    case (Absyn.QUALIFIED(name = id1, path = path),
          Absyn.IDENT(name = id2), _)
      equation
        true = stringEqual(id1, id2);
      then
        path;
    
    // adrpo: leave it as stripped as you can if you can't match it above and stripPartial is true
    case (Absyn.QUALIFIED(name = id1, path = path), env_path, true)
      equation
        false = stringEqual(id1, Absyn.pathFirstIdent(env_path));
      then
        inPath;
  end matchcontinue;
end pathStripEnvPrefix2;

public function daeCrefStripEnvPrefix
"Removes the entire environment prefix from the given component reference, or
 returns the unchanged reference."
  input DAE.ComponentRef inCref;
  input Env inEnv;
  input Boolean stripPartial;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnv, stripPartial)
    local
      Absyn.Path env_path;
      DAE.ComponentRef cref1, cref2;

    case (_, _, _)
      equation
        SOME(env_path) = getEnvPath(inEnv);
        cref1 = inCref;
        env_path = Absyn.makeNotFullyQualified(env_path);
        // try to strip as much as possible
        cref2 = daeCrefStripEnvPrefix2(cref1, env_path, stripPartial);
        // check if we really did anything, fail if we did nothing!
        false = ComponentReference.crefEqual(cref1, cref2);
      then
        cref2;

    else inCref;
  end matchcontinue;
end daeCrefStripEnvPrefix;

protected function daeCrefStripEnvPrefix2
  input DAE.ComponentRef inCref;
  input Absyn.Path inEnvPath;
  input Boolean stripPartial;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inEnvPath, stripPartial)
    local
      Absyn.Ident id1, id2;
      DAE.ComponentRef cref;
      Absyn.Path env_path;

    case (DAE.CREF_QUAL(ident = id1, subscriptLst = {}, componentRef = cref),
          Absyn.QUALIFIED(name = id2, path = env_path), _)
      equation
        true = stringEqual(id1, id2);
      then
        daeCrefStripEnvPrefix2(cref, env_path, stripPartial);

    case (DAE.CREF_QUAL(ident = id1, subscriptLst = {}, componentRef = cref),
          Absyn.IDENT(name = id2), _)
      equation
        true = stringEqual(id1, id2);
      then
        cref;
    
    // adrpo: leave it as stripped as you can if you can't match it above and stripPartial is true
    case (DAE.CREF_QUAL(ident = id1, subscriptLst = {}, componentRef = _),
          env_path, true)
      equation
        false = stringEqual(id1, Absyn.pathFirstIdent(env_path));
      then
        inCref;
  end matchcontinue;
end daeCrefStripEnvPrefix2;

public function envPrefixOf
  input Env inPrefixEnv;
  input Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := envPrefixOf2(listReverse(inPrefixEnv), listReverse(inEnv));
end envPrefixOf;

public function envPrefixOf2
  "Checks if one environment is a prefix of another."
  input Env inPrefixEnv;
  input Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := matchcontinue(inPrefixEnv, inEnv)
    local
      String n1, n2;
      Env rest1, rest2;

    case ({}, _) then true;

    case (FRAME(name = NONE()) :: rest1, FRAME(name = NONE()) :: rest2)
      then envPrefixOf2(rest1, rest2);

    case (FRAME(name = SOME(n1)) :: rest1, FRAME(name = SOME(n2)) :: rest2)
      equation
        true = stringEqual(n1, n2);
      then
        envPrefixOf2(rest1, rest2);

    else false;
  end matchcontinue;
end envPrefixOf2;

public function isImplicitScope
  input Option<Ident> inIdent;
  output Boolean isImplicit;
algorithm
  isImplicit := match(inIdent)
    local
      Ident id;
    case (NONE()) then false;
    case (SOME(id))
      then stringGet(id,1) == 36; // "$"
  end match;
end isImplicitScope;

public function envEqualPrefix
  input Env inEnv1;
  input Env inEnv2;
  output Env outPrefix;
algorithm
  outPrefix := envEqualPrefix2(listReverse(inEnv1), listReverse(inEnv2), {});
end envEqualPrefix;

public function envEqualPrefix2
  input Env inEnv1;
  input Env inEnv2;
  input Env inAccumEnv;
  output Env outPrefix;
algorithm
  outPrefix := matchcontinue(inEnv1, inEnv2, inAccumEnv)
    local
      String name1, name2;
      Env env, rest_env1, rest_env2;
      Frame frame;

    case ((frame as FRAME(name = SOME(name1))) :: rest_env1,
          FRAME(name = SOME(name2)) :: rest_env2, _)
      equation
        true = stringEq(name1, name2);
        env = envEqualPrefix2(rest_env1, rest_env2, frame :: inAccumEnv);
      then
        env;

    case (FRAME(name = NONE()) :: rest_env1, FRAME(name = NONE()) :: rest_env2, _)
      then envEqualPrefix2(rest_env1, rest_env2, inAccumEnv);

    else inAccumEnv;

  end matchcontinue;
end envEqualPrefix2;

public function daeCrefStripEnvIfFullyQualifedInEnv
"@author: adrpo
 strip the environment prefix from cref
 if the cref is fully qualified in env"
  input DAE.ComponentRef inCref;
  input Env inEnv;
  output DAE.ComponentRef outCref;
algorithm
  false := true;
  // not in top env!
  false := isTopScope(inEnv);
  true := isIdentOnlyInTop(ComponentReference.crefFirstIdent(inCref), inEnv);
  outCref := daeCrefStripEnvPrefix(inCref, inEnv, true);
  false := ComponentReference.crefEqualNoStringCompare(outCref, inCref);
  /*
  print("DC->: " +& ComponentReference.printComponentRefStr(inCref) +& 
      "\nDC<-" +& ComponentReference.printComponentRefStr(outCref) +& 
      "\nE:" +& getEnvNameStr(inEnv) +& "\n");*/
end daeCrefStripEnvIfFullyQualifedInEnv;

public function crefStripEnvIfFullyQualifedInEnv
"@author: adrpo
 strip the environment prefix from cref
 if the cref is fully qualified in env"
  input Absyn.ComponentRef inCref;
  input Env inEnv;
  output Absyn.ComponentRef outCref;
algorithm
  false := true;
  // not in top env!
  false := isTopScope(inEnv);
  true := isIdentOnlyInTop(Absyn.crefFirstIdent(inCref), inEnv);
  outCref := crefStripEnvPrefix(inCref, inEnv, true);
  false := Absyn.crefEqual(outCref, inCref);
  /*
  print("C->: " +& Absyn.printComponentRefStr(inCref) +& 
      "\nC<-" +& Absyn.printComponentRefStr(outCref) +& 
      "\nE:" +& getEnvNameStr(inEnv) +& "\n");*/
end crefStripEnvIfFullyQualifedInEnv;

public function pathStripEnvIfFullyQualifedInEnv
"@author: adrpo
 strip the environment prefix from path
 if the path is fully qualified in env"
  input Absyn.Path inPath;
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  false := true;
  // not in top env!
  false := isTopScope(inEnv);
  true := isFullyQualifiedInEnv(inPath, inEnv);
  outPath := pathStripEnvPrefix(inPath, inEnv, true);
  false := Absyn.pathEqual(outPath, inPath);
  /*
  print("P->: " +& Absyn.pathString(inPath) +& 
      "\nP<-" +& Absyn.pathString(outPath) +& 
      "\nE:" +& getEnvNameStr(inEnv) +& "\n");*/
end pathStripEnvIfFullyQualifedInEnv;

public function isFullyQualifiedInEnv
"@author: adrpo
 checks that qualifed paths are actually fully qualifed.
 if the first id in the path is only found in top then
 the path is fully qualifed and we return true."
  input Absyn.Path inPath;
  input Env inEnv;
  output Boolean isFQ;
algorithm
  isFQ := match(inPath, inEnv)
    local Ident id; Boolean b;
    case (Absyn.FULLYQUALIFIED(_), _) then true;
    case (_, _)
      equation
        id = Absyn.pathFirstIdent(inPath);
        b = isIdentOnlyInTop(id, inEnv);
      then
        b;
  end match;
end isFullyQualifiedInEnv;

public function isIdentOnlyInTop
"@author: adrpo
 checks that the given id is not defined in any frame but top"
  input Ident inId;
  input Env inEnv;
  output Boolean isFQ;
algorithm
  isFQ := matchcontinue(inId, inEnv)
    local Frame f; Env fs; Ident id; Boolean b;
    
    case (_, {}) then false;
    
    // we found it
    case (_, f::_)
      equation
        _ = getItemInEnv(inId, {f});
        b = isTopScope({f});
      then 
        b;
    
    // we haven't found it
    case (_, f::fs)
      equation
        failure(_ = getItemInEnv(inId, {f}));
        b = isIdentOnlyInTop(inId, fs);
      then
        b;
  end matchcontinue;
end isIdentOnlyInTop;

end Env;
