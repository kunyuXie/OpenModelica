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

encapsulated package FGraphDump
" file:        FGraphDump.mo
  package:     FGraphDump
  description: A graph for instantiation

  RCS: $Id: FGraphDump.mo 14085 2012-11-27 12:12:40Z adrpo $

  This module builds a graph out of SCode 
"

public import SCode;
public import DAE;
public import FCore;
public import FNode;
public import FGraph;

public
type Name = FCore.Name;
type Id = FCore.Id;
type Seq = FCore.Seq;
type Next = FCore.Next;
type Node = FCore.Node;
type Data = FCore.Data;
type Kind = FCore.Kind;
type Ref = FCore.Ref;
type Refs = FCore.Refs;
type Children = FCore.Children;
type Parents = FCore.Parents;
type ImportTable = FCore.ImportTable;
type Extra = FCore.Extra;
type Visited = FCore.Visited;
type Import = FCore.Import;
type Graph = FCore.Graph;

type Type = DAE.Type;
type Types = list<DAE.Type>;

protected 
import Flags;
import GraphML;
import List;
import Dump;
import Absyn;
import Util;

public function dumpGraph
  input Graph inGraph;
  input String fileName;
algorithm  
  _ := matchcontinue(inGraph, fileName)
    local
      Integer g;
      GraphML.GraphInfo gi;
      Ref nr;
    
    case (_, _)
      equation
        false = Flags.isSet(Flags.GRAPH_INST_GEN_GRAPH);
      then
        ();
    
    case (_, _)
      equation
        gi = GraphML.createGraphInfo();
        (gi,(_,g)) = GraphML.addGraph("G",false,gi);
        nr = FGraph.top(inGraph); 
        ((gi,g)) = addNodes((gi,g), {nr});
        print("Dumping graph file: " +& fileName +& " ....\n");
        GraphML.dumpGraph(gi, fileName);
        print("Dumped\n");
      then
        ();
  
  end matchcontinue;
end dumpGraph;

protected function addNodes
  input tuple<GraphML.GraphInfo,Integer> gin;
  input list<Ref> inRefs;
  output tuple<GraphML.GraphInfo,Integer> gout;
algorithm
  gout := matchcontinue(gin, inRefs)
    local 
      tuple<GraphML.GraphInfo,Integer> g;
      list<Ref> rest;
      Ref n;
    
    case (_, {}) then gin;

    case (g, n::rest)
      equation
        // if not userdefined or top, skip it
        true = not FNode.isRefTop(n) and 
               not FNode.isRefUserDefined(n);
        g = addNodes(g, rest);
      then
        g;
        

    case (g, n::rest)
      equation
        g = addNode(g, FNode.fromRef(n));
        g = addNodes(g, rest);
      then
        g;
  
  end matchcontinue;
end addNodes;

protected function addNode
  input tuple<GraphML.GraphInfo,Integer> gin;
  input Node node;
  output tuple<GraphML.GraphInfo,Integer> gout;
algorithm
  gout := match(gin, node)
    local 
      GraphML.GraphInfo gi;
      Integer i, id;
      Children kids;
      Name name;
      Data nd;
      String n, nds, color, labelText;
      GraphML.ShapeType shape;
      Ref nr, target;
      list<Ref> nrefs;
      GraphML.NodeLabel label;
      GraphML.EdgeLabel elabel;
    
    // top node
    case ((gi,i), FCore.N(parents = {}, children = kids))
      equation
        (color, shape, nds) = graphml(node);
        labelText = nds; 
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        
        (gi, _) = GraphML.addNode(
              "n" +& intString(FNode.id(node)),
              color, {label}, shape, NONE(), {}, i, gi);
                
        nrefs = List.map(FNode.getAvlTreeValues({SOME(kids)}, {}), FNode.getAvlValue);
        ((gi,i)) = addNodes((gi,i), nrefs);
      then
        ((gi,i));
    
    // REF node, do not add it, just add an edge between parent and target
    case ((gi,i), FCore.N(parents = nr::_, children = kids, data = FCore.REF(target)))
      equation

        (color, shape, nds) = graphml(node);
         
        labelText = nds;
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN()); 
        elabel = GraphML.EDGELABEL(nds, NONE(), GraphML.FONTSIZE_SMALL);
        
        
        (gi, _) = GraphML.addNode(
              "n" +& intString(FNode.id(node)),
              color, {label}, shape, NONE(), {}, i, gi);
        
        (gi, _) = GraphML.addEdge(
                   "r" +& intString(FNode.id(node)), 
                   "n" +& intString(FNode.id(node)), 
                   "n" +& intString(FNode.id(FNode.fromRef(nr))), 
                   GraphML.COLOR_RED,
                   GraphML.LINE(),
                   GraphML.LINEWIDTH_STANDARD, 
                   false,
                   {elabel},
                   (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                   {},
                   gi);
        
        /*
        // add ref edge
        (gi, _) = GraphML.addEdge(
                   "r" +& intString(FNode.id(node)),
                   "n" +& intString(FNode.id(FNode.fromRef(target))),
                   "n" +& intString(FNode.id(FNode.fromRef(nr))), 
                   GraphML.COLOR_RED,
                   GraphML.DASHED(),
                   GraphML.LINEWIDTH_STANDARD, 
                   false, 
                   {elabel},
                   (GraphML.ARROWNONE(),GraphML.ARROWSTANDART()),
                   {},
                   gi);*/
        
        nrefs = List.map(FNode.getAvlTreeValues({SOME(kids)}, {}), FNode.getAvlValue);
        ((gi,i)) = addNodes((gi,i), nrefs);
      then
        ((gi,i));
    
    // other nodes
    case ((gi,i), FCore.N(parents = nr::_, children = kids))
      equation
        (color, shape, nds) = graphml(node);
        
        labelText = nds; 
        label = GraphML.NODELABEL_INTERNAL(labelText,NONE(),GraphML.FONTPLAIN());
        elabel = GraphML.EDGELABEL(nds, NONE(), GraphML.FONTSIZE_SMALL); 
        
        (gi, _) = GraphML.addNode(
              "n" +& intString(FNode.id(node)),
              color, {label}, shape, NONE(), {}, i, gi);
        
        (gi, _) = GraphML.addEdge(
                   "e" +& intString(FNode.id(node)), 
                   "n" +& intString(FNode.id(node)), 
                   "n" +& intString(FNode.id(FNode.fromRef(nr))), 
                   GraphML.COLOR_BLACK,
                   GraphML.LINE(),
                   GraphML.LINEWIDTH_STANDARD, 
                   false, 
                   {}, // {elabel},
                   (GraphML.ARROWNONE(),GraphML.ARROWNONE()),
                   {},
                   gi);
                
        nrefs = List.map(FNode.getAvlTreeValues({SOME(kids)}, {}), FNode.getAvlValue);
        ((gi,i)) = addNodes((gi,i), nrefs);
      then
        ((gi,i));
    
  end match;
end addNode;

protected function graphml
  input Node node;
  output String color;
  output GraphML.ShapeType shape;
  output String nname;
algorithm
  (color, shape, nname) := matchcontinue(node)
    local
      Children kids;
      Parents p;
      Name name;
      Integer id;
      Name n;
      Data nd;
      SCode.Element e;
      Absyn.Exp exp;
      Absyn.ComponentRef r;
      String s;
      Absyn.ArrayDim dims;
      Ref target;
      Boolean b;
    
    // redeclare class
    case (FCore.N(name, id, p, kids, nd as FCore.CL(e = e)))
      equation
        true = SCode.isElementRedeclare(e);
        b = FNode.isClassExtends(node);
        s = Util.if_(b, "rdCE:", "rdC:");
        s = s +& FNode.name(node);
      then 
        (GraphML.COLOR_YELLOW, GraphML.HEXAGON(), s);
    
    // replaceable class
    case (FCore.N(name, id, p, kids, nd as FCore.CL(e = e)))
      equation
        true = SCode.isElementReplaceable(e);
        b = FNode.isClassExtends(node);
        s = Util.if_(b, "rpCE:", "rpC:");
        s = s +& FNode.name(node); 
      then 
        (GraphML.COLOR_RED, GraphML.RECTANGLE(), s);
    
    // redeclare component
    case (FCore.N(name, id, p, kids, nd as FCore.CO(e = e)))
      equation
        true = SCode.isElementRedeclare(e); 
        s = "rdc:" +& FNode.name(node);
      then 
        (GraphML.COLOR_YELLOW, GraphML.ELLIPSE(), s);
    
    // replaceable component
    case (FCore.N(name, id, p, kids, nd as FCore.CO(e = e)))
      equation
        true = SCode.isElementReplaceable(e);
        s = "rpc:" +& FNode.name(node);
      then 
        (GraphML.COLOR_RED, GraphML.ELLIPSE(), s);
    
    // class
    case (FCore.N(name, id, p, kids, nd as FCore.CL(e = _)))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.name(node);
      then 
        (GraphML.COLOR_GRAY, GraphML.RECTANGLE(), s);

    // component
    case (FCore.N(name, id, p, kids, nd as FCore.CO(e =_ )))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.name(node);
      then 
        (GraphML.COLOR_WHITE, GraphML.ELLIPSE(), s);

    // extends
    case (FCore.N(name, id, p, kids, nd as FCore.EX(e = _)))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.name(node);
      then 
        (GraphML.COLOR_GREEN, GraphML.ROUNDRECTANGLE(), s);

    // derived
    case (FCore.N(name, id, p, kids, nd as FCore.DE(d = _)))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.name(node);
      then 
        (GraphML.COLOR_GREEN, GraphML.ROUNDRECTANGLE(), s);
    
    // expressions: bindings, condition in conditional components, array dim, etc
    case (FCore.N(name, id, p, kids, nd as FCore.EXP(e = exp)))
      equation
        s = FNode.dataStr(nd) +& ":" +& Util.escapeModelicaStringToXmlString(Dump.printExpStr(exp));
      then 
        (GraphML.COLOR_PURPLE, GraphML.HEXAGON(), s);
        
    // dimensions
    case (FCore.N(name, id, p, kids, nd as FCore.DIMS(name = _, dims = dims))) 
      equation
        s = FNode.dataStr(nd) +& ":" +& Util.escapeModelicaStringToXmlString(Dump.printArraydimStr(dims));      
      then 
        (GraphML.COLOR_PINK, GraphML.TRIANGLE(), s);

    // component references
    case (FCore.N(name, id, p, kids, nd as FCore.CR(r = r)))
      equation
        s = FNode.dataStr(nd) +& ":" +& Absyn.printComponentRefStr(r);
      then 
        (GraphML.COLOR_PURPLE, GraphML.OCTAGON(), s);

    // REF nodes
    case (FCore.N(name, id, p, kids, nd as FCore.REF(target)))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.toPathStr(FNode.fromRef(target));
      then 
        (GraphML.COLOR_ORANGE, GraphML.TRAPEZOID(), s);

    // CLONE nodes
    case (FCore.N(name, id, p, kids, nd as FCore.CLONE(target)))
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.toPathStr(FNode.fromRef(target));
      then 
        (GraphML.COLOR_ORANGE, GraphML.TRIANGLE(), s);

    // all others
    case (FCore.N(name, id, p, kids, nd)) 
      equation
        s = FNode.dataStr(nd) +& ":" +& FNode.name(node);
      then 
        (GraphML.COLOR_BLUE, GraphML.ELLIPSE(), s);
  end matchcontinue;
end graphml;

end FGraphDump;
