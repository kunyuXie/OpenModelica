/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
/*
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

//! @brief Contains functions used for parsing results obtained from OpenModelica Compiler.

#include "StringHandler.h"
#include "Helper.h"
#include "Utilities.h"

QString StringHandler::mLastOpenDir;

//! @class StringHandler
//! @brief The StringHandler class is used to manipulating and parsing the results get from OMC.

//! Constructor
StringHandler::StringHandler()
{

}

//! Destructor
StringHandler::~StringHandler()
{

}

QString StringHandler::getModelicaClassType(int type)
{
  switch (type)
  {
    case StringHandler::Model:
      return "Model";
    case StringHandler::Class:
      return "Class";
    case StringHandler::Connector:
      return "Connector";
    case StringHandler::ExpandableConnector:
      return "Expandable Connector";
    case StringHandler::Record:
      return "Record";
    case StringHandler::Block:
      return "Block";
    case StringHandler::Function:
      return "Function";
    case StringHandler::Package:
      return "Package";
    case StringHandler::Type:
      return "Type";
    case StringHandler::Operator:
      return "Operator";
    case StringHandler::OperatorRecord:
      return "Operator Record";
    case StringHandler::OperatorFunction:
      return "Operator Function";
    case StringHandler::Optimization:
      return "Optimization";
    case StringHandler::Primitive:
      return "Primitive";
    case StringHandler::Parameter:
      return "Parameter";
    case StringHandler::Constant:
      return "Constant";
    case StringHandler::Protected:
      return "Protected";
    default:
      // should never be reached
      return "";
  }
}

StringHandler::ModelicaClasses StringHandler::getModelicaClassType(QString type)
{
  if (type.toLower().contains("model"))
    return StringHandler::Model;
  else if (type.toLower().contains("class"))
    return StringHandler::Class;
  else if (type.toLower().contains("connector"))
    return StringHandler::Connector;
  else if (type.toLower().contains("operator record"))
    return StringHandler::OperatorRecord;
  else if (type.toLower().contains("operator function"))
    return StringHandler::OperatorFunction;
  else if (type.toLower().contains("record"))
    return StringHandler::Record;
  else if (type.toLower().contains("block"))
    return StringHandler::Block;
  else if (type.toLower().contains("function"))
    return StringHandler::Function;
  else if (type.toLower().contains("package"))
    return StringHandler::Package;
  else if (type.toLower().contains("type"))
    return StringHandler::Type;
  else if (type.toLower().contains("operator"))
    return StringHandler::Operator;
  else if (type.toLower().contains("optimization"))
    return StringHandler::Optimization;
  else if (type.toLower().contains("primitive"))
    return StringHandler::Primitive;
  else if (type.toLower().contains("parameter"))
    return StringHandler::Parameter;
  else if (type.toLower().contains("constant"))
    return StringHandler::Constant;
  else if (type.toLower().contains("protected"))
    return StringHandler::Protected;
  else
    return StringHandler::Model;
}

QString StringHandler::getViewType(int type)
{
  switch (type)
  {
    case StringHandler::Icon:
      return Helper::iconView;
    case StringHandler::Diagram:
      return Helper::diagramView;
    case StringHandler::ModelicaText:
      return Helper::textView;
    default:
      // should never be reached
      return "";
  }
}

StringHandler::OpenModelicaErrorKinds StringHandler::getErrorKind(QString errorKind)
{
  if (errorKind.compare(Helper::syntaxKind) == 0) {
    return StringHandler::Syntax;
  } else if (errorKind.compare(Helper::grammarKind) == 0) {
    return StringHandler::Grammar;
  } else if (errorKind.compare(Helper::translationKind) == 0) {
    return StringHandler::Translation;
  } else if (errorKind.compare(Helper::symbolicKind) == 0) {
    return StringHandler::Symbolic;
  } else if (errorKind.compare(Helper::simulationKind) == 0) {
    return StringHandler::Simulation;
  } else if (errorKind.compare(Helper::scriptingKind) == 0) {
    return StringHandler::Scripting;
  } else {
    return StringHandler::NoOMErrorKind;
  }
}

QString StringHandler::getErrorKindString(OpenModelicaErrorKinds errorKind)
{
  switch (errorKind)
  {
    case StringHandler::Syntax:
      return tr("Syntax");
    case StringHandler::Grammar:
      return tr("Grammar");
    case StringHandler::Translation:
      return tr("Translation");
    case StringHandler::Symbolic:
      return tr("Symbolic");
    case StringHandler::Simulation:
      return tr("Simulation");
    case StringHandler::Scripting:
      return tr("Scripting");
    default:
      // should never be reached
      return "";
  }
}

StringHandler::OpenModelicaErrors StringHandler::getErrorType(QString errorType)
{
  if (errorType.compare(Helper::notificationLevel) == 0) {
    return StringHandler::Notification;
  } else if (errorType.compare(Helper::warningLevel) == 0) {
    return StringHandler::Warning;
  } else if (errorType.compare(Helper::errorLevel) == 0) {
    return StringHandler::OMError;
  } else {
    return StringHandler::NoOMError;
  }
}

QString StringHandler::getErrorTypeDisplayString(StringHandler::OpenModelicaErrors errorType)
{
  switch (errorType) {
    case StringHandler::Notification:
      return tr("Notification");
    case StringHandler::Warning:
      return tr("Warning");
    case StringHandler::OMError:
      return tr("Error");
    case StringHandler::NoOMError:
    default:
      return tr("Unknown");
  }
}

QString StringHandler::getErrorTypeString(StringHandler::OpenModelicaErrors errorType)
{
  switch (errorType) {
    case StringHandler::Warning:
      return Helper::warningLevel;
    case StringHandler::OMError:
      return Helper::errorLevel;
    case StringHandler::Notification:
    case StringHandler::NoOMError:
    default:
      return Helper::notificationLevel;
  }
}

Qt::PenStyle StringHandler::getLinePatternType(StringHandler::LinePattern type)
{
  switch (type)
  {
    case StringHandler::LineNone:
      return Qt::NoPen;
    case StringHandler::LineSolid:
      return Qt::SolidLine;
    case StringHandler::LineDash:
      return Qt::DashLine;
    case StringHandler::LineDot:
      return Qt::DotLine;
    case StringHandler::LineDashDot:
      return Qt::DashDotLine;
    case StringHandler::LineDashDotDot:
      return Qt::DashDotDotLine;
    default:
      // should never be reached
      return Qt::SolidLine;
  }
}

StringHandler::LinePattern StringHandler::getLinePatternType(QString type)
{
  if (type.compare("LinePattern.None") == 0)
    return StringHandler::LineNone;
  else if (type.compare("LinePattern.Solid") == 0)
    return StringHandler::LineSolid;
  else if (type.compare("LinePattern.Dash") == 0)
    return StringHandler::LineDash;
  else if (type.compare("LinePattern.Dot") == 0)
    return StringHandler::LineDot;
  else if (type.compare("LinePattern.DashDot") == 0)
    return StringHandler::LineDashDot;
  else if (type.compare("LinePattern.DashDotDot") == 0)
    return StringHandler::LineDashDotDot;
  else
    return StringHandler::LineSolid;
}

QString StringHandler::getLinePatternString(StringHandler::LinePattern type)
{
  switch (type)
  {
    case StringHandler::LineNone:
      return "LinePattern.None";
    case StringHandler::LineSolid:
      return "LinePattern.Solid";
    case StringHandler::LineDash:
      return "LinePattern.Dash";
    case StringHandler::LineDot:
      return "LinePattern.Dot";
    case StringHandler::LineDashDot:
      return "LinePattern.DashDot";
    case StringHandler::LineDashDotDot:
      return "LinePattern.DashDotDot";
    default:
      // should never be reached
      return "LinePattern.Solid";
  }
}

QComboBox* StringHandler::getLinePatternComboBox()
{
  QComboBox *pLinePatternComboBox = new QComboBox;
  pLinePatternComboBox->setIconSize(QSize(58, 16));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-none.svg"), getLinePatternString(LineNone));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-solid.svg"), getLinePatternString(LineSolid));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-dash.svg"), getLinePatternString(LineDash));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-dot.svg"), getLinePatternString(LineDot));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-dash-dot.svg"), getLinePatternString(LineDashDot));
  pLinePatternComboBox->addItem(QIcon(":/Resources/icons/line-dash-dot-dot.svg"), getLinePatternString(LineDashDotDot));
  return pLinePatternComboBox;
}

Qt::BrushStyle StringHandler::getFillPatternType(FillPattern type)
{
  switch (type)
  {
    case StringHandler::FillNone:
      return Qt::NoBrush;
    case StringHandler::FillSolid:
      return Qt::SolidPattern;
    case StringHandler::FillHorizontal:
      return Qt::HorPattern;
    case StringHandler::FillVertical:
      return Qt::VerPattern;
    case StringHandler::FillCross:
      return Qt::CrossPattern;
    case StringHandler::FillForward:
      return Qt::FDiagPattern;
    case StringHandler::FillBackward:
      return Qt::BDiagPattern;
    case StringHandler::FillCrossDiag:
      return Qt::DiagCrossPattern;
    case StringHandler::FillHorizontalCylinder:
      return Qt::LinearGradientPattern;
    case StringHandler::FillVerticalCylinder:
      return Qt::Dense1Pattern;
    case StringHandler::FillSphere:
      return Qt::RadialGradientPattern;
    default:
      // should never be reached
      return Qt::NoBrush;
  }
}

StringHandler::FillPattern StringHandler::getFillPatternType(QString type)
{
  if (type.compare("FillPattern.None") == 0)
    return StringHandler::FillNone;
  else if (type.compare("FillPattern.Solid") == 0)
    return StringHandler::FillSolid;
  else if (type.compare("FillPattern.Horizontal") == 0)
    return StringHandler::FillHorizontal;
  else if (type.compare("FillPattern.Vertical") == 0)
    return StringHandler::FillVertical;
  else if (type.compare("FillPattern.Cross") == 0)
    return StringHandler::FillCross;
  else if (type.compare("FillPattern.Forward") == 0)
    return StringHandler::FillForward;
  else if (type.compare("FillPattern.Backward") == 0)
    return StringHandler::FillBackward;
  else if (type.compare("FillPattern.CrossDiag") == 0)
    return StringHandler::FillCrossDiag;
  else if (type.compare("FillPattern.HorizontalCylinder") == 0)
    return StringHandler::FillHorizontalCylinder;
  else if (type.compare("FillPattern.VerticalCylinder") == 0)
    return StringHandler::FillVerticalCylinder;
  else if (type.compare("FillPattern.Sphere") == 0)
    return StringHandler::FillSphere;
  else
    return StringHandler::FillNone;
}

QString StringHandler::getFillPatternString(StringHandler::FillPattern type)
{
  switch (type)
  {
    case StringHandler::FillNone:
      return "FillPattern.None";
    case StringHandler::FillSolid:
      return "FillPattern.Solid";
    case StringHandler::FillHorizontal:
      return "FillPattern.Horizontal";
    case StringHandler::FillVertical:
      return "FillPattern.Vertical";
    case StringHandler::FillCross:
      return "FillPattern.Cross";
    case StringHandler::FillForward:
      return "FillPattern.Forward";
    case StringHandler::FillBackward:
      return "FillPattern.Backward";
    case StringHandler::FillCrossDiag:
      return "FillPattern.CrossDiag";
    case StringHandler::FillHorizontalCylinder:
      return "FillPattern.HorizontalCylinder";
    case StringHandler::FillVerticalCylinder:
      return "FillPattern.VerticalCylinder";
    case StringHandler::FillSphere:
      return "FillPattern.Sphere";
    default:
      // should never be reached
      return "FillPattern.None";
  }
}

QComboBox* StringHandler::getFillPatternComboBox()
{
  QComboBox *pFillPatternComboBox = new QComboBox;
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-none.svg"), getFillPatternString(FillNone));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-solid.svg"), getFillPatternString(FillSolid));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-horizontal.svg"), getFillPatternString(FillHorizontal));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-vertical.svg"), getFillPatternString(FillVertical));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-cross.svg"), getFillPatternString(FillCross));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-forward.svg"), getFillPatternString(FillForward));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-backward.svg"), getFillPatternString(FillBackward));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-cross-diagnol.svg"), getFillPatternString(FillCrossDiag));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-horizontal-cylinder.svg"), getFillPatternString(FillHorizontalCylinder));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-vertical-cylinder.svg"), getFillPatternString(FillVerticalCylinder));
  pFillPatternComboBox->addItem(QIcon(":/Resources/icons/fill-sphere.svg"), getFillPatternString(FillSphere));
  return pFillPatternComboBox;
}

StringHandler::BorderPattern StringHandler::getBorderPatternType(QString type)
{
  if (type.compare("BorderPattern.None") == 0)
    return StringHandler::BorderNone;
  else if (type.compare("BorderPattern.Raised") == 0)
    return StringHandler::BorderRaised;
  else if (type.compare("BorderPattern.Sunken") == 0)
    return StringHandler::BorderSunken;
  else if (type.compare("BorderPattern.Engraved") == 0)
    return StringHandler::BorderEngraved;
  else
    return StringHandler::BorderNone;
}

QString StringHandler::getBorderPatternString(StringHandler::BorderPattern type)
{
  switch (type)
  {
    case StringHandler::BorderNone:
      return "BorderPattern.None";
    case StringHandler::BorderRaised:
      return "BorderPattern.Raised";
    case StringHandler::BorderSunken:
      return "BorderPattern.Sunken";
    case StringHandler::BorderEngraved:
      return "BorderPattern.Engraved";
    default:
      return "BorderPattern.None";
  }
}

StringHandler::Smooth StringHandler::getSmoothType(QString type)
{
  if (type.compare("Smooth.None") == 0)
    return StringHandler::SmoothNone;
  else if (type.compare("Smooth.Bezier") == 0)
    return StringHandler::SmoothBezier;
  else
    return StringHandler::SmoothNone;
}

QString StringHandler::getSmoothString(StringHandler::Smooth type)
{
  switch (type)
  {
    case StringHandler::SmoothNone:
      return "Smooth.None";
    case StringHandler::SmoothBezier:
      return "Smooth.Bezier";
    default:
      // should never be reached
      return "Smooth.None";
  }
}

StringHandler::Arrow StringHandler::getArrowType(QString type)
{
  if (type.compare("Arrow.None") == 0)
    return StringHandler::ArrowNone;
  else if (type.compare("Arrow.Open") == 0)
    return StringHandler::ArrowOpen;
  else if (type.compare("Arrow.Filled") == 0)
    return StringHandler::ArrowFilled;
  else if (type.compare("Arrow.Half") == 0)
    return StringHandler::ArrowHalf;
  else
    return StringHandler::ArrowNone;
}

QString StringHandler::getArrowString(StringHandler::Arrow type)
{
  switch (type)
  {
    case StringHandler::ArrowNone:
      return "Arrow.None";
    case StringHandler::ArrowOpen:
      return "Arrow.Open";
    case StringHandler::ArrowFilled:
      return "Arrow.Filled";
    case StringHandler::ArrowHalf:
      return "Arrow.Half";
    default:
      // should never be reached
      return "Arrow.None";
  }
}

QComboBox* StringHandler::getStartArrowComboBox()
{
  QComboBox *pStartArrowComboBox = new QComboBox;
  pStartArrowComboBox->setIconSize(QSize(58, 16));
  pStartArrowComboBox->addItem(QIcon(":/Resources/icons/line-solid.svg"), getArrowString(ArrowNone));
  pStartArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-start-open.svg"), getArrowString(ArrowOpen));
  pStartArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-start-fill.svg"), getArrowString(ArrowFilled));
  pStartArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-start-open-half.svg"), getArrowString(ArrowHalf));
  return pStartArrowComboBox;
}

QComboBox* StringHandler::getEndArrowComboBox()
{
  QComboBox *pEndArrowComboBox = new QComboBox;
  pEndArrowComboBox->setIconSize(QSize(58, 16));
  pEndArrowComboBox->addItem(QIcon(":/Resources/icons/line-solid.svg"), getArrowString(ArrowNone));
  pEndArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-end-open.svg"), getArrowString(ArrowOpen));
  pEndArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-end-fill.svg"), getArrowString(ArrowFilled));
  pEndArrowComboBox->addItem(QIcon(":/Resources/icons/arrow-end-open-half.svg"), getArrowString(ArrowHalf));
  return pEndArrowComboBox;
}

int StringHandler::getFontWeight(QList<StringHandler::TextStyle> styleList)
{
  foreach (StringHandler::TextStyle textStyle, styleList)
  {
    if (textStyle == StringHandler::TextStyleBold)
      return QFont::Bold;
  }
  return QFont::Normal;
}

bool StringHandler::getFontItalic(QList<StringHandler::TextStyle> styleList)
{
  foreach (StringHandler::TextStyle textStyle, styleList)
  {
    if (textStyle == StringHandler::TextStyleItalic)
      return true;
  }
  return false;
}

bool StringHandler::getFontUnderline(QList<StringHandler::TextStyle> styleList)
{
  foreach (StringHandler::TextStyle textStyle, styleList)
  {
    if (textStyle == StringHandler::TextStyleUnderLine)
      return true;
  }
  return false;
}

Qt::Alignment StringHandler::getTextAlignment(StringHandler::TextAlignment alignment)
{
  switch (alignment)
  {
    case StringHandler::TextAlignmentLeft:
      return Qt::AlignLeft;
    case StringHandler::TextAlignmentCenter:
      return Qt::AlignCenter;
    case StringHandler::TextAlignmentRight:
      return Qt::AlignRight;
    default:
      return Qt::AlignCenter;
  }
}

StringHandler::TextAlignment StringHandler::getTextAlignmentType(QString alignment)
{
  if (alignment.compare("TextAlignment.Left") == 0)
    return StringHandler::TextAlignmentLeft;
  else if (alignment.compare("TextAlignment.Center") == 0)
    return StringHandler::TextAlignmentCenter;
  else if (alignment.compare("TextAlignment.Right") == 0)
    return StringHandler::TextAlignmentRight;
  else
    return StringHandler::TextAlignmentCenter;
}

QString StringHandler::getTextAlignmentString(StringHandler::TextAlignment alignment)
{
  switch (alignment)
  {
    case StringHandler::TextAlignmentLeft:
      return "TextAlignment.Left";
    case StringHandler::TextAlignmentCenter:
      return "TextAlignment.Center";
    case StringHandler::TextAlignmentRight:
      return "TextAlignment.Right";
    default:
      return "TextAlignment.Center";
  }
}

QString StringHandler::getTextStyleString(StringHandler::TextStyle textStyle)
{
  switch (textStyle)
  {
    case StringHandler::TextStyleBold:
      return "TextStyle.Bold";
    case StringHandler::TextStyleItalic:
      return "TextStyle.Italic";
    case StringHandler::TextStyleUnderLine:
      return "TextStyle.UnderLine";
    default:
      return "TextStyle.Bold";
  }
}

//! Removes the first and last curly brackest {} from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastCurlBrackets(QString value)
{
  value = value.trimmed();
  if (value.length() > 1 && value.at(0) == '{' && value.at(value.length() - 1) == '}')
  {
    value = value.mid(1, (value.length() - 2));
  }
  return value;
}

//! Removes the first and last brackest () from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastBrackets(QString value)
{
  value = value.trimmed();
  if (value.length() > 1 && value.at(0) == '(' && value.at(value.length() - 1) == ')')
  {
    value = value.mid(1, (value.length() - 2));
  }
  return value;
}

//! Removes the first and last quotes "" from the string.
//! @param value is the string which is parsed.
QString StringHandler::removeFirstLastQuotes(QString value)
{
  value = value.trimmed();
  if (value.length() > 1 && value.at(0) == '\"' && value.at(value.length() - 1) == '\"')
  {
    value = value.mid(1, (value.length() - 2));
  }
  return value;
}

/*!
 * \brief StringHandler::getSubStringBeforeDots
 * Returns the first word from a string.
 * \param value -  is the string which is parsed.
 * \return
 */
QString StringHandler::getSubStringBeforeDots(QString value)
{
  if (value.isEmpty())
  {
    return "";
  }
  value = value.trimmed();
  QStringList list = value.split(".", QString::SkipEmptyParts);
  return list.at(0);
}

QStringList StringHandler::getStrings(QString value)
{
  return getStrings(value, '{', '}');
}

QStringList StringHandler::getStrings(QString value, char start, char end)
{
  QStringList list;
  bool mask = false;
  bool inString = false;
  char StringEnd = '\0';
  int begin = 0;
  int ele = 0;

  for (int i = 0 ; i < value.length() ; i++)
  {
    if (inString)
    {
      if (mask)
      {
        mask = false;
      }
      else
      {
        if (value.at(i) == '\\')
        {
          mask = true;
        }
        else if (value.at(i) == StringEnd)
        {
          inString = false;
        }
      }
    }
    else
    {
      if (value.at(i) == '"')
      {
          StringEnd = '"';
          inString = true;
      }
      else if (value.at(i) == '\'')
      {
          StringEnd = '\'';
          inString = true;
      }
      else if (value.at(i) == ',')
      {
        if (ele == 0)
        {
          list.append(value.mid(begin,i-begin).trimmed());
          begin = i+1;
        }
      }
      else if (value.at(i) == start)
      {
        ele++;
      }
      else if (value.at(i) == end)
      {
        ele--;
      }
    }
  }
  list.append(value.mid(begin,value.length()-begin).trimmed());

  return list;
}

/*!
 * \brief wordsBeforeAfterLastDot
 * Helper for StringHandler::getLastWordAfterDot() and StringHandler::removeLastWordAfterDot()
 * \param value
 * \param lastWord
 * \return
 */
static QString wordsBeforeAfterLastDot(QString value, bool lastWord)
{
  if (value.isEmpty())
  {
    return "";
  }
  value = value.trimmed();
  int pos;
  if (value.endsWith('\'')) {
    int i = value.size()-2;
    while (value[i] != '\'' && i>1 && value[i-1] != '\\') {
      i--;
    }
    pos = i-1;
  } else {
    pos = value.lastIndexOf('.');
  }

  if (pos >= 0)
  {
    if (lastWord)
      return value.mid((pos + 1), (value.length() - 1));
    else
      return value.mid(0, (pos));
  }
  else
  {
    return value;
  }
}

/*!
 * \brief StringHandler::getLastWordAfterDot
 * Returns the last word after dot.
 * \param value
 * \return
 */
QString StringHandler::getLastWordAfterDot(QString value)
{
  return wordsBeforeAfterLastDot(value, true);
}

/*!
 * \brief StringHandler::removeLastWordAfterDot
 * Removes the last word after dot and returns the remaining string.
 * \param value
 * \return
 */
QString StringHandler::removeLastWordAfterDot(QString value)
{
  return wordsBeforeAfterLastDot(value, false);
}

/*!
 * \brief wordsBeforeAfterFirstDot
 * Helper for StringHandler::getFirstWordBeforeDot() and StringHandler::removeFirstWordAfterDot()
 * \param value
 * \param firstWord
 * \return
 */
static QString wordsBeforeAfterFirstDot(QString value, bool firstWord)
{
  if (value.isEmpty()) {
    return "";
  }
  value = value.trimmed();
  int pos;
  if (value.startsWith('\'')) {
    int i = 1;
    while (value[i] != '\'' && i<value.size()-1 && value[i+1] != '\\') {
      i++;
    }
    pos = i+1;
  } else {
    pos = value.indexOf('.');
  }

  if (pos >= 0) {
    if (firstWord) {
      return value.mid(0, (pos));
    } else {
      return value.mid((pos + 1), (value.length() - 1));
    }
  } else {
    return value;
  }
}

/*!
 * \brief StringHandler::getFirstWordBeforeDot
 * Returns the first word before dot.
 * \param value
 * \return
 */
QString StringHandler::getFirstWordBeforeDot(QString value)
{
  return wordsBeforeAfterFirstDot(value, true);
}

/*!
 * \brief StringHandler::removeFirstWordAfterDot
 * Removes the first word before dot and returns the remaining string.
 * \param value
 * \return
 */
QString StringHandler::removeFirstWordAfterDot(QString value)
{
  return wordsBeforeAfterFirstDot(value, false);
}

QString StringHandler::getModifierValue(QString value)
{
  int element = 0;
  for(int i = 0 ; i < value.length() ; i++)
  {
    if (value.at(i) == '(')
      element++;
    else if (value.at(i) == ')')
      element--;
    else if (value.at(i) == '=')
    {
      if (element == 0)
        return value.mid(i + 1);
    }
  }
  return "";
}

QString StringHandler::escapeString(QString value)
{
  QString res;
  value = value.trimmed();
  for (int i = 0; i < value.length(); i++) {
    switch (value[i].toAscii()) {
      case '"':  res.append('\"');     break;
      case '\\': res.append("\\\\");   break;
      case '\a': res.append("\\a");    break;
      case '\b': res.append("\\b");    break;
      case '\f': res.append("\\f");    break;
      case '\n': res.append("\\n");    break;
      case '\r': res.append("\\r");    break;
      case '\t': res.append("\\t");    break;
      case '\v': res.append("\\v");    break;
      default:   res.append(value[i]); break;
    }
  }
  return res;
}

#define CONSUME_CHAR(value,res,i) \
  if (value.at(i) == '\\') { \
  i++; \
  switch (value[i].toAscii()) { \
  case '\'': res.append('\''); break; \
  case '"':  res.append('\"'); break; \
  case '?':  res.append('\?'); break; \
  case '\\': res.append('\\'); break; \
  case 'a':  res.append('\a'); break; \
  case 'b':  res.append('\b'); break; \
  case 'f':  res.append('\f'); break; \
  case 'n':  res.append('\n'); break; \
  case 'r':  res.append('\r'); break; \
  case 't':  res.append('\t'); break; \
  case 'v':  res.append('\v'); break; \
  } \
  } else { \
  res.append(value[i]); \
  }

QString StringHandler::unparse(QString value)
{
  QString res;
  value = value.trimmed();
  if (value.length() > 1 && value.at(0) == '\"' && value.at(value.length() - 1) == '\"') {
    value = value.mid(1, (value.length() - 2));
    for (int i=0; i < value.length(); i++) {
      CONSUME_CHAR(value,res,i);
    }
    return res;
  } else {
    return "";
  }
}

QStringList StringHandler::unparseStrings(QString value)
{
  QStringList lst;
  value = value.trimmed();
  if (value[0] != '{') return lst; // ERROR?
  int i=1;
  QString res;
  while (value[i] == '"') {
    i++;
    while (value.at(i) != '"') {
      CONSUME_CHAR(value,res,i);
      i++;
      /* if we have unexpected double quotes then, however omc should return \" */
      /* remove this block once fixed in omc */
      if (value[i] == '"' && value[i+1] != ',') {
        if (value[i+1] != '}') {
          CONSUME_CHAR(value,res,i);
          i++;
        }
      }
      /* remove this block once fixed in omc */
    }
    i++;
    if (value[i] == '}') {
      lst.append(res);
      return lst;
    }
    if (value[i] == ',') {
      lst.append(res);
      i++;
      res = "";
      while (value[i] == ' ')     // if we have space before next value e.g {"x", "y", "z"}
        i++;
      continue;
    }
    while (value[i] != '"' && value[i] != '\0') {
      i++;
      fprintf(stderr, "error? malformed string-list. skipping: %c\n", value[i].toAscii());
    }
  }
  return lst; // ERROR?
}

QStringList StringHandler::unparseArrays(QString value)
{
  QStringList lst;
  size_t braceopen = 0;
  size_t mainbraceopen = 0;
  size_t i = 0;
  value = StringHandler::removeFirstLastCurlBrackets(value);
  size_t length = value.size();
  int subbraceopen = 0;
  for (; i < length ; i++) {
    if (value.at(i) == ' ' || value.at(i) == ',') {
      continue; // ignore any kind of space
    }
    if (value.at(i) == '{' && braceopen == 0) {
      braceopen = 1;
      mainbraceopen = i;
      continue;
    }
    if (value.at(i) == '{') {
      subbraceopen = 1;
    }

    if (value.at(i) == '}' && braceopen == 1 && subbraceopen == 0) {
      //closing of a group
      int copylength = i- mainbraceopen+1;
      braceopen = 0;
      lst.append(value.mid(mainbraceopen, copylength));
      continue;
    }
    if (value.at(i) == '}') {
      subbraceopen = 0;
    }

    /* skip the whole quotes section */
    if (value.at(i) == '"')
    {
      i++;
      while (value.at(i) != '"')
      {
        i++;
        if (value.at(i) == '"' && value.at(i+1) != ',') {
          if (value.at(i+1) != '}') {
            i+=2;
          }
        }
      }
    }
  }
  return lst;
}

bool StringHandler::unparseBool(QString value)
{
  value = value.trimmed();
  return value == "true";
}

QString StringHandler::getSaveFileName(QWidget* parent, const QString &caption, QString * dir, const QString &filter, QString * selectedFilter,
                                       const QString &defaultSuffix, const QString *purposedName)
{
  QString dir_str;
  QString fileName;

  if (dir)
  {
    dir_str = *dir;
  }
  else
  {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  /* Add the extension with purposedName because if the directory with the same name exists then
   * QFileDialog::getSaveFileName takes the user to that directory and does not show the purposedName.
   */
  QString purposedFileName = *purposedName;
  if (!purposedFileName.isEmpty() && !defaultSuffix.isEmpty())
    purposedFileName = QString(purposedFileName).append(".").append(defaultSuffix);

  if (!purposedFileName.isEmpty()) {
    fileName = QFileDialog::getSaveFileName(parent, caption, QString(dir_str).append("/").append(purposedFileName), filter, selectedFilter);
  } else {
    fileName = QFileDialog::getSaveFileName(parent, caption, dir_str, filter, selectedFilter);
  }

  if (!fileName.isEmpty()) {
    /* Qt is not reallllyyyy platform independent :(
     * In older versions of Qt QFileDialog::getSaveFileName doesn't return file extension on Linux.
     * But it works fine in Qt 4.8.
     */
    QFileInfo fileInfo(fileName);
#if defined(Q_OS_LINUX) && QT_VERSION < 0x040800
    if (fileInfo.suffix() == QString(""))
      fileName.append(".").append(defaultSuffix);
#else
    Q_UNUSED(defaultSuffix);
#endif
    mLastOpenDir = fileInfo.absolutePath();
    return fileName;
  }
  return QString();
}

QString StringHandler::getOpenFileName(QWidget* parent, const QString &caption, QString * dir, const QString &filter, QString * selectedFilter)
{
  QString dir_str;

  if (dir) {
    dir_str = *dir;
  } else {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  QString fileName = QString();
#ifdef WIN32
  fileName = QFileDialog::getOpenFileName(parent, caption, dir_str, filter, selectedFilter);
#else
  Q_UNUSED(selectedFilter)
  QFileDialog *dialog;
  dialog = new QFileDialog(parent, caption, dir_str, filter);
  QList<QUrl> urls = dialog->sidebarUrls();
  urls << QUrl("file://" + OpenModelica::tempDirectory());
  dialog->setSidebarUrls(urls);
  dialog->setFileMode(QFileDialog::ExistingFile);
  if (dialog->exec()) {
    fileName = dialog->selectedFiles()[0];
  }
  delete dialog;
#endif
  if (!fileName.isEmpty()) {
    QFileInfo fileInfo(fileName);
    mLastOpenDir = fileInfo.absolutePath();
  }
  return fileName;
}

QStringList StringHandler::getOpenFileNames(QWidget* parent, const QString &caption, QString * dir, const QString &filter, QString * selectedFilter)
{
  QString dir_str;

  if (dir) {
    dir_str = *dir;
  } else {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  QStringList fileNames;
#ifdef WIN32
  fileNames = QFileDialog::getOpenFileNames(parent, caption, dir_str, filter, selectedFilter);
#else
  Q_UNUSED(selectedFilter);
  QFileDialog *dialog;
  dialog = new QFileDialog(parent, caption, dir_str, filter);
  QList<QUrl> urls = dialog->sidebarUrls();
  urls << QUrl("file://" + OpenModelica::tempDirectory());
  dialog->setSidebarUrls(urls);
  dialog->setFileMode(QFileDialog::ExistingFiles);
  if (dialog->exec()) {
    fileNames = dialog->selectedFiles();
  }
  delete dialog;
#endif
  if (!fileNames.isEmpty()) {
    QFileInfo fileInfo(fileNames.at(0));
    mLastOpenDir = fileInfo.absolutePath();
  }
  return fileNames;
}

QString StringHandler::getExistingDirectory(QWidget *parent, const QString &caption, QString *dir)
{
  QString dir_str;

  if (dir) {
    dir_str = *dir;
  } else {
    dir_str = mLastOpenDir.isEmpty() ? QDir::homePath() : mLastOpenDir;
  }

  QString dirName = QFileDialog::getExistingDirectory(parent, caption, dir_str, QFileDialog::ShowDirsOnly);
  if (!dirName.isEmpty()) {
    mLastOpenDir = dirName;
    return dirName;
  }
  return QString();
}

void StringHandler::setLastOpenDirectory(QString lastOpenDirectory)
{
  mLastOpenDir = lastOpenDirectory;
}

QString StringHandler::getLastOpenDirectory()
{
  return mLastOpenDir;
}

QStringList StringHandler::getDialogAnnotation(QString componentAnnotation)
{
  if (componentAnnotation.toLower().contains("error")) {
    return QStringList();
  }
  componentAnnotation = StringHandler::removeFirstLastCurlBrackets(componentAnnotation);
  if (componentAnnotation.isEmpty()) {
    return QStringList();
  }
  QStringList annotations = StringHandler::getStrings(componentAnnotation, '(', ')');
  foreach (QString annotation, annotations) {
    if (annotation.startsWith("Dialog")) {
      annotation = annotation.mid(QString("Dialog").length());
      annotation = StringHandler::removeFirstLastBrackets(annotation);
      return StringHandler::getStrings(annotation);
    }
  }
  return QStringList();
}

QString StringHandler::getPlacementAnnotation(QString componentAnnotation)
{
  if (componentAnnotation.toLower().contains("error")) {
    return QString();
  }
  componentAnnotation = StringHandler::removeFirstLastCurlBrackets(componentAnnotation);
  if (componentAnnotation.isEmpty()) {
    return QString();
  }
  QStringList annotations = StringHandler::getStrings(componentAnnotation, '(', ')');
  foreach (QString annotation, annotations) {
    if (annotation.startsWith("Placement")) {
      return StringHandler::removeFirstLastBrackets(annotation);
    }
  }
  return QString();
}

/*!
  Reduces Angle to useful values. Finds the angle between 0° and 360°.\n
  This functin is useful for performing shapes and components flipping.\n\n
  <B>Find the angle between 0° and 360° that corresponds to 1275°</B>\n\n
  1275 ÷ 360 = 3.541 the only part we care about is the "3", which tells us that 360° fits into 1275° three times,\n
  1275° – 3×360° = 1275° – 1080° = 195°\n\n
  <B>Find an angle between 0° and 360° that corresponds to –3742°</B>\n\n
  This works somewhat similarly to the previous examples. First we will find how often 360° fits inside 3742°,\n
  3742 ÷ 360 = 10.394\n
  But since this angle was negative, so we actually need one extra round to carry us into the positive angle values,
  so we will use 11 instead of 10,\n
  –3742 + 11 × 360 = –3742 + 3960 = 218.
  \param angle - the angle to be normalized.
  \return the normalized angle.
  */
qreal StringHandler::getNormalizedAngle(qreal angle)
{
  qreal multiplier = fabs(angle)/360;
  qreal normalizedAngle = angle;
  if (angle < 0) {
    normalizedAngle = angle + (qCeil(multiplier) * 360);
  } else {
    normalizedAngle = angle - (qFloor(multiplier) * 360);
  }
  return normalizedAngle;
}

/*!
  Takes a string and splits it on space. The space within quotes are preserved.
  \param value - the string to split.
  \return the list of strings.
  */
QStringList StringHandler::splitStringWithSpaces(QString value)
{
  QStringList lst;
  QString res;
  bool quotesOpen = false;
  value = value.trimmed();
  for (int i = 0 ; i < value.size() ; i++) {
    if (value.at(i) == ' ' && !quotesOpen) {
      lst.append(res);
      res.clear();
    } else if (value.at(i) == '"' && quotesOpen) {
      quotesOpen = false;
    } else if (value.at(i) == '"' && !quotesOpen) {
      quotesOpen = true;
    } else {
      res.append(value.at(i));
    }
  }
  if (!res.isEmpty()) {
    lst.append(res);
  }
  return lst;
}

void StringHandler::fillEncodingComboBox(QComboBox *pEncodingComboBox)
{
  /* get the available MIBS and sort them. */
  QList<int> mibs = QTextCodec::availableMibs();
  qSort(mibs);
  QList<int> sortedMibs;
  foreach (int mib, mibs) {
    if (mib >= 0) {
      sortedMibs += mib;
    }
  }
  foreach (int mib, mibs) {
    if (mib < 0) {
      sortedMibs += mib;
    }
  }
  foreach (int mib, sortedMibs)
  {
    /* get the codec from MIB */
    QTextCodec *pCodec = QTextCodec::codecForMib(mib);
    QString codecName = QString::fromLatin1(pCodec->name());
    QString codecNameWithAliases = codecName;
    /* get all the aliases of the codec */
    foreach (const QByteArray &alias, pCodec->aliases()) {
      codecNameWithAliases += QLatin1String(" / ") + QString::fromLatin1(alias);
    }
    pEncodingComboBox->addItem(codecNameWithAliases, codecName);
  }
  int currentIndex = pEncodingComboBox->findData(Helper::utf8);
  if (currentIndex > -1) {
    pEncodingComboBox->setCurrentIndex(currentIndex);
  }
}

QStringList StringHandler::makeVariableParts(QString variable)
{
  return variable.split(QRegExp("\\.(?![^\\[\\]]*\\])"), QString::SkipEmptyParts);
}

bool StringHandler::isCFile(QString extension)
{
  if (extension.compare("c") == 0 ||
      extension.compare("cpp") == 0 ||
      extension.compare("cc") == 0 ||
      extension.compare("h") == 0 ||
      extension.compare("hpp") == 0)
    return true;
  else
    return false;
}

bool StringHandler::isModelicaFile(QString extension)
{
  if (extension.compare("mo") == 0)
    return true;
  else
    return false;
}

bool StringHandler::naturalSort(const QString &s1, const QString &s2) {
  int i1 = 0; // index in string
  int i2 = 0;
  while (true) {
    if (s2.length() == i2) // both strings identical or s1 larger than s2
      return s1.length() == i1 ? true : false;
    if (s1.length() == i1) return true; // s1 smaller than s2

    unsigned short u1 = s1[i1].unicode();
    unsigned short u2 = s2[i2].unicode();

    if (u1 >= '0' && u1 <= '9' && u2 >= '0' && u2 <= '9') {
      // parse both numbers completely and compare them
      quint64 n1 = 0; // the parsed number
      quint64 n2 = 0;
      int l1 = 0; // length of the number
      int l2 = 0;
      do {
        ++l1;
        n1 = n1 * 10 + u1 - '0';
        if (++i1 == s1.length()) break;
        u1 = s1[i1].unicode();
      } while (u1 >= '0' && u1 <= '9');
      do {
        ++l2;
        n2 = n2 * 10 + u2 - '0';
        if (++i2 == s2.length()) break;
        u2 = s2[i2].unicode();
      } while (u2 >= '0' && u2 <= '9');
      // compare two numbers
      if (n1 < n2) return true;
      if (n1 > n2) return false;
      // only accept identical numbers if they also have the same length
      // (same number of leading zeros)
      if (l1 < l2) return true;
      if (l1 > l2) return false;
    } else {
      // compare digit with non-digit or two non-digits
      if (u1 < u2) return true;
      if (u1 > u2) return false;
      ++i1;
      ++i2;
    }
  }
}

#ifdef WIN32
QProcessEnvironment StringHandler::compilationProcessEnvironment(QString *pCompilationProcessPath)
{
  QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
  const char *OMDEV = getenv("OMDEV");
  if (QString(OMDEV).isEmpty()) {
    QString OMHOME = QString(Helper::OpenModelicaHome).replace("/", "\\");
    QString MinGWBin = OMHOME + "\\MinGW\\bin";
    QString MinGWLibExec = OMHOME + "\\MinGW\\libexec\\gcc\\mingw32\\4.4.0";
    environment.insert("PATH", MinGWBin + ";" + MinGWLibExec);
    *pCompilationProcessPath = "\"" + OMHOME + "\\MinGW\\bin\\mingw32-make.exe" + "\"";
  } else {
    QString qOMDEV = QString(OMDEV).replace("/", "\\");
    QString MinGWBin = qOMDEV + "\\tools\\mingw\\bin";
    QString MinGWLibExec = qOMDEV + "\\tools\\mingw\\libexec\\gcc\\mingw32\\4.4.0";
    environment.insert("PATH", MinGWBin + ";" + MinGWLibExec);
    *pCompilationProcessPath = "\"" + qOMDEV + "\\tools\\mingw\\bin\\mingw32-make.exe" + "\"";
  }
  return environment;
}

QProcessEnvironment StringHandler::simulationProcessEnvironment()
{
  QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
  const char *OMDEV = getenv("OMDEV");
  if (QString(OMDEV).isEmpty()) {
    QString OMHOME = QString(Helper::OpenModelicaHome).replace("/", "\\");
    QString MinGWBin = OMHOME + "\\MinGW\\bin";
    environment.insert("PATH", MinGWBin + ";" + environment.value("PATH"));
  } else {
    QString qOMDEV = QString(OMDEV).replace("/", "\\");
    QString MinGWBin = qOMDEV + "\\tools\\mingw\\bin";
    environment.insert("PATH", MinGWBin + ";" + environment.value("PATH"));
  }
  return environment;
}
#endif

StringHandler::SimulationMessageType StringHandler::getSimulationMessageType(QString type)
{
  if (type == "info") {
    return StringHandler::Info;
  } else if (type == "warning") {
    return StringHandler::SMWarning;
  } else if (type == "error") {
    return StringHandler::Error;
  } else if (type == "assert") {
    return StringHandler::Assert;
  } else if (type == "debug") {
    return StringHandler::Debug;
  } else if (type == "OMEditInfo") {
    return StringHandler::OMEditInfo;
  } else {
    return StringHandler::Unknown;
  }
}

QString StringHandler::getSimulationMessageTypeString(StringHandler::SimulationMessageType type)
{
  switch (type) {
    case StringHandler::Info:
      return "info";
    case StringHandler::SMWarning:
      return "warning";
    case StringHandler::Error:
      return "error";
    case StringHandler::Assert:
      return "assert";
    case StringHandler::Debug:
      return "debug";
    case StringHandler::OMEditInfo:
      return "OMEditInfo";
    default:
      return "unknown";
  }
}

QColor StringHandler::getSimulationMessageTypeColor(StringHandler::SimulationMessageType type)
{
  switch (type) {
    case StringHandler::OMEditInfo:
      return Qt::blue;
    case StringHandler::SMWarning:
    case StringHandler::Error:
    case StringHandler::Assert:
    case StringHandler::Debug:
      return Qt::red;
    case StringHandler::Info:
    case StringHandler::Unknown:
    default:
      return Qt::black;
      break;
  }
}

/*!
 * \brief StringHandler::makeClassNameRelative
 * Removes the first characters matching with droppedClassName from draggedClassName.
 * \param draggedClassName
 * \param droppedClassName
 * \return
 */
QString StringHandler::makeClassNameRelative(QString draggedClassName, QString droppedClassName)
{
  if (getFirstWordBeforeDot(draggedClassName).compare(getFirstWordBeforeDot(droppedClassName)) == 0) {
    return makeClassNameRelative(removeFirstWordAfterDot(draggedClassName), removeFirstWordAfterDot(droppedClassName));
  } else {
    return draggedClassName;
  }
}

/*!
 * \brief StringHandler::toCamelCase
 * Converts the string to camel case.
 * \param str
 * \return the string converted to camel case.
 */
QString StringHandler::toCamelCase(QString str)
{
  QString s = str;
  s[0] = s[0].toLower();
  return s;
}
