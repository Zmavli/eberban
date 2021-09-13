// eberban PEG grammar - v0.44.1
// =============================

// GRAMMAR
// main text rule
{
  var _g_foreign_quote_delim;

  function _join(arg) {
    if (typeof(arg) == "string")
      return arg;
    else if (arg) {
      var ret = "";
      for (var v in arg) { if (arg[v]) ret += _join(arg[v]); }
      return ret;
    }
  }

  function _node_empty(label, arg) {
    var ret = [];
    if (label) ret.push(label);
    if (arg && typeof arg == "object" && typeof arg[0] == "string" && arg[0]) {
      ret.push( arg );
      return ret;
    }
    if (!arg)
    {
      return ret;
    }
    return _node_int(label, arg);
  }

  function _node_int(label, arg) {
    if (typeof arg == "string")
      return arg;
    if (!arg) arg = [];
    var ret = [];
    if (label) ret.push(label);
    for (var v in arg) {
      if (arg[v] && arg[v].length != 0)
        ret.push( _node_int( null, arg[v] ) );
    }
    return ret;
  }

  function _node2(label, arg1, arg2) {
    return [label].concat(_node_empty(arg1)).concat(_node_empty(arg2));
  }

  function _node(label, arg) {
    var _n = _node_empty(label, arg);
    return (_n.length == 1 && label) ? [] : _n;
  }
  var _node_nonempty = _node;

  // === Functions for faking left recursion === //

  function _flatten_node(a) {
    // Flatten nameless nodes
    // e.g. [Name1, [[Name2, X], [Name3, Y]]] --> [Name1, [Name2, X], [Name3, Y]]
    if (is_array(a)) {
      var i = 0;
      while (i < a.length) {
        if (!is_array(a[i])) i++;
        else if (a[i].length === 0) // Removing []s
          a = a.slice(0, i).concat(a.slice(i + 1));
        else if (is_array(a[i][0]))
          a = a.slice(0, i).concat(a[i], a.slice(i + 1));
        else i++;
      }
    }
    return a;
  }

  function _group_leftwise(arr) {
    if (!is_array(arr)) return [];
    else if (arr.length <= 2) return arr;
    else return [_group_leftwise(arr.slice(0, -1)), arr[arr.length - 1]];
  }

  // "_lg" for "Leftwise Grouping".
  function _node_lg(label, arg) {
    return _node(label, _group_leftwise(_flatten_node(arg)));
  }

  function _node_lg2(label, arg) {
    if (is_array(arg) && arg.length == 2)
      arg = arg[0].concat(arg[1]);
    return _node(label, _group_leftwise(arg));
  }

  // === Foreign words functions === //

  function _assign_foreign_quote_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: foreign_quote word is of type " + typeof w;
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    _g_foreign_quote_delim = w;
    return;
  }

  function _is_foreign_quote_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: foreign_quote word is of type " + typeof w;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    w = w.replace(/[.\t\n\r?!\u0020]/g, "");
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    return w === _g_foreign_quote_delim;
  }

  function join_expr(n) {
    if (!is_array(n) || n.length < 1) return "";
    var s = "";
    var i = is_array(n[0]) ? 0 : 1;
    while (i < n.length) {
      s += is_string(n[i]) ? n[i] : join_expr(n[i]);
      i++;
    }
    return s;
  }

  function is_string(v) {
    // return $.type(v) === "string";
    return Object.prototype.toString.call(v) === '[object String]';
  }

  function is_array(v) {
    // return $.type(v) === "array";
    return Object.prototype.toString.call(v) === '[object Array]';
  }
}

text = expr:((free_interjection / free_parenthetical)* paragraphs? spaces? EOF?) {return _node("text", expr);}

// text structure
paragraphs = expr:(paragraph (&PU_clause paragraph)*) {return _node("paragraphs", expr);}
paragraph = expr:(PU_clause? paragraph_unit (&(PA_clause / PO_clause) paragraph_unit)*) {return _node("paragraph", expr);}

paragraph_unit = expr:(paragraph_unit_erased / paragraph_unit_1) {return _node("paragraph_unit", expr);}
paragraph_unit_erased = expr:(paragraph_unit_1 CU_clause) {return _node("paragraph_unit_erased", expr);}
paragraph_unit_1 = expr:(definition / sentence) {return _node("paragraph_unit_1", expr);}

arguments_list = expr:((KI_clause / GI_clause)* PI_clause) {return _node("arguments_list", expr);}

definition = expr:(PO_clause defined scope POI_clause_elidible) {return _node("definition", expr);}
defined = expr:(GI_clause / freeform_variable / predicate_compound / predicate_root) {return _node("defined", expr);}
sentence = expr:(PA_clause_elidible scope PAI_clause_elidible) {return _node("sentence", expr);}

// scope
scope = expr:(arguments_list? scope_1) {return _node("scope", expr);}

scope_1 = expr:(scope_sequence / scope_2) {return _node("scope_1", expr);}
scope_sequence = expr:(scope_sequence_item (BU_clause scope_sequence_item)+) {return _node("scope_sequence", expr);}
scope_sequence_item = expr:(scope_2) {return _node("scope_sequence_item", expr);}

scope_2 = expr:(chaining) {return _node("scope_2", expr);}

// chaining and explicit switches
chaining = expr:((chaining_neg / chaining_unit)+) {return _node("chaining", expr);}
chaining_neg = expr:(BI_clause chaining) {return _node("chaining_neg", expr);}
chaining_unit = expr:(predicate ve_scope?) {return _node("chaining_unit", expr);}
ve_scope = expr:(ve_scope_first ve_scope_next* VEI_clause_elidible) {return _node("ve_scope", expr);}
ve_scope_first = expr:(BI_clause? VE_clause scope) {return _node("ve_scope_first", expr);}
ve_scope_next = expr:(BI_clause? FE_clause scope) {return _node("ve_scope_next", expr);}

// predicate unit
predicate = expr:(predicate_1 free*) {return _node("predicate", expr);}
predicate_1 = expr:((SE_clause !SE_clause / ZI_clause)* predicate_2) {return _node("predicate_1", expr);}
predicate_2 = expr:(BA_clause / MI_clause / predicate_quote / predicate_variable / predicate_scope / predicate_borrowing / predicate_root / predicate_number / predicate_compound) {return _node("predicate_2", expr);}

predicate_root = expr:(spaces? root) {return _node("predicate_root", expr);}
predicate_number = expr:(spaces? number) {return _node("predicate_number", expr);}
predicate_compound = expr:(spaces? compound) {return _node("predicate_compound", expr);}
predicate_borrowing = expr:(borrowing_group) {return _node("predicate_borrowing", expr);}
predicate_scope = expr:(PE_clause scope PEI_clause_elidible) {return _node("predicate_scope", expr);}

// quotes
predicate_quote = expr:(grammatical_quote / one_word_quote / foreign_quote) {return _node("predicate_quote", expr);}
grammatical_quote = expr:(CA_clause text CAI_clause) {return _node("grammatical_quote", expr);}
one_word_quote = expr:(CE_clause spaces? (native_word / compound / borrowing)) {return _node("one_word_quote", expr);}
foreign_quote = expr:(CO_clause spaces? foreign_quote_open space_char foreign_quote_content pause_char foreign_quote_close) {return _node("foreign_quote", expr);}
foreign_quote_content = expr:((!(pause_char foreign_quote_close) .)*) { return ["foreign_quote_content", _join(expr)]; }

// numbers
number = expr:(TI_clause+ BE_clause_elidible) {return _node("number", expr);}

// borrowings
borrowing_group = expr:((spaces? borrowing)+ BE_clause_elidible) {return _node("borrowing_group", expr);}

// variables
predicate_variable = expr:(BO_clause? (KI_clause / GI_clause / spaces? freeform_variable)) {return _node("predicate_variable", expr);}

// free affixes
override = expr:(DU_clause predicate_1) {return _node("override", expr);} // avoid nested free

free = expr:(free_metadata / free_parenthetical / free_subscript / free_interjection) {return _node("free", expr);}
free_metadata = expr:(DA_clause) {return _node("free_metadata", expr);}
free_subscript = expr:(DI_clause number) {return _node("free_subscript", expr);}
free_parenthetical = expr:(DO_clause text DOI_clause) {return _node("free_parenthetical", expr);}
free_interjection = expr:(DE_clause predicate_1) {return _node("free_interjection", expr);} // avoid nested free

// PARTICLES CLAUSES
BA_clause = expr:(spaces? BA) {return _node("BA_clause", expr);} // inline argument
BE_clause = expr:(spaces? BE) {return _node("BE_clause", expr);} // miscellaneous terminator
BI_clause = expr:(spaces? BI free*) {return _node("BI_clause", expr);} // wide-scope negation
BO_clause = expr:(spaces? BO) {return _node("BO_clause", expr);} // variable assignement
BU_clause = expr:(spaces? BU) {return _node("BU_clause", expr);} // sequence separator
 //
DA_clause = expr:(spaces? DA) {return _node("DA_clause", expr);} // free metadata
DE_clause = expr:(spaces? DE) {return _node("DE_clause", expr);} // free interjection
DI_clause = expr:(spaces? DI) {return _node("DI_clause", expr);} // free subscript
DO_clause = expr:(spaces? DO) {return _node("DO_clause", expr);} // free parenthetical starter
DOI_clause = expr:(spaces? DOI) {return _node("DOI_clause", expr);} // free parenthetical terminator
DU_clause = expr:(spaces? DU) {return _node("DU_clause", expr);} // free particle override
 //
SE_clause = expr:(spaces? SE override?) {return _node("SE_clause", expr);} // chaining override
ZI_clause = expr:(spaces? ZI override?) {return _node("ZI_clause", expr);} // predicate transformation
VE_clause = expr:(spaces? VE override? free*) {return _node("VE_clause", expr);} // explicit switch + VE-scope
FE_clause = expr:(spaces? FE override? free*) {return _node("FE_clause", expr);} // next explicit switch
VEI_clause = expr:(spaces? VEI) {return _node("VEI_clause", expr);} // VE-scope terminator
 //
GI_clause = expr:(spaces? GI) {return _node("GI_clause", expr);} // predicate variables
KI_clause = expr:(spaces? KI) {return _node("KI_clause", expr);} // individual variables
MI_clause = expr:(spaces? MI) {return _node("MI_clause", expr);} // discourse predicates
 //
PA_clause = expr:(spaces? PA free*) {return _node("PA_clause", expr);} // sentence starter
PAI_clause = expr:(spaces? PAI free*) {return _node("PAI_clause", expr);} // sentence terminator
PE_clause = expr:(spaces? PE free*) {return _node("PE_clause", expr);} // predicate scope starter
PEI_clause = expr:(spaces? PEI) {return _node("PEI_clause", expr);} // predicate scope elidible terminator
PI_clause = expr:(spaces? PI) {return _node("PI_clause", expr);} // arguments sequence terminator
PO_clause = expr:(spaces? PO free*) {return _node("PO_clause", expr);} // definition starter
POI_clause = expr:(spaces? POI free*) {return _node("POI_clause", expr);} // definition terminator
PU_clause = expr:(spaces? PU free*) {return _node("PU_clause", expr);} // paragraph marker
 //
TI_clause = expr:(spaces? TI) {return _node("TI_clause", expr);} // numbers/digits
 //
CA_clause = expr:(spaces? CA) {return _node("CA_clause", expr);} // grammatical quote starter
CAI_clause = expr:(spaces? CAI) {return _node("CAI_clause", expr);} // grammatical quote terminator
CE_clause = expr:(spaces? CE) {return _node("CE_clause", expr);} // one word quote
CO_clause = expr:(spaces? CO) {return _node("CO_clause", expr);} // foreign quote
 //
CU_clause = expr:(spaces? CU) {return _node("CU_clause", expr);} // paragraph unit eraser

BE_clause_elidible = expr:(BE_clause?) {return (expr == "" || !expr) ? ["BE"] : _node_empty("BE_clause_elidible", expr);}
PA_clause_elidible = expr:(PA_clause?) {return (expr == "" || !expr) ? ["PA"] : _node_empty("PA_clause_elidible", expr);}
PAI_clause_elidible = expr:(PAI_clause?) {return (expr == "" || !expr) ? ["PAI"] : _node_empty("PAI_clause_elidible", expr);}
PEI_clause_elidible = expr:(PEI_clause?) {return (expr == "" || !expr) ? ["PEI"] : _node_empty("PEI_clause_elidible", expr);}
POI_clause_elidible = expr:(POI_clause?) {return (expr == "" || !expr) ? ["POI"] : _node_empty("POI_clause_elidible", expr);}
VEI_clause_elidible = expr:(VEI_clause?) {return (expr == "" || !expr) ? ["VEI"] : _node_empty("VEI_clause_elidible", expr);}

// PARTICLE FAMILIES
BA = expr:(&particle (b a) &post_word) {return _node("BA", expr);}
BE = expr:(&particle (b &e hieaou) &post_word) {return _node("BE", expr);}
BI = expr:(&particle (b i) &post_word) {return _node("BI", expr);}
BO = expr:(&particle (b o) &post_word) {return _node("BO", expr);}
BU = expr:(&particle (b &u hieaou) &post_word) {return _node("BU", expr);}
CA = expr:(&particle !(CAI &post_word) (c &a hieaou) &post_word) {return _node("CA", expr);}
CAI = expr:(&particle (c a i) &post_word) {return _node("CAI", expr);}
CE = expr:(&particle (c &e hieaou) &post_word) {return _node("CE", expr);}
CO = expr:(&particle (c &o hieaou) &post_word) {return _node("CO", expr);}
CU = expr:(&particle (c u) &post_word) {return _node("CU", expr);}
DA = expr:(&particle (d &a hieaou) &post_word) {return _node("DA", expr);}
DE = expr:(&particle (d &e hieaou) &post_word) {return _node("DE", expr);}
DI = expr:(&particle (d i) &post_word) {return _node("DI", expr);}
DO = expr:(&particle (d o) &post_word) {return _node("DO", expr);}
DOI = expr:(&particle (d o i) &post_word) {return _node("DOI", expr);}
DU = expr:(&particle (d u) &post_word) {return _node("DU", expr);}
FE = expr:(&particle (f hieaou) &post_word) {return _node("FE", expr);}
GI = expr:(&particle (g hieaou) &post_word) {return _node("GI", expr);}
KI = expr:(&particle (k hieaou) &post_word) {return _node("KI", expr);}
MI = expr:(&particle (m hieaou) &post_word) {return _node("MI", expr);}
PA = expr:(&particle !(PAI &post_word) (p &a hieaou) &post_word) {return _node("PA", expr);}
PAI = expr:(&particle (p a i) &post_word) {return _node("PAI", expr);}
PE = expr:(&particle (p e) &post_word) {return _node("PE", expr);}
PEI = expr:(&particle (p e i) &post_word) {return _node("PEI", expr);}
PI = expr:(&particle (p &i hieaou) &post_word) {return _node("PI", expr);}
PO = expr:(&particle !(POI &post_word) (p &o hieaou) &post_word) {return _node("PO", expr);}
POI = expr:(&particle (p o i) &post_word) {return _node("POI", expr);}
PU = expr:(&particle (p &u hieaou) &post_word) {return _node("PU", expr);}
SE = expr:(&particle (s hieaou) &post_word) {return _node("SE", expr);}
TI = expr:(&particle (t hieaou) / digit &post_word) {return _node("TI", expr);}
VE = expr:(&particle !(VEI &post_word) (v hieaou) &post_word) {return _node("VE", expr);}
VEI = expr:(&particle (v e i) &post_word) {return _node("VEI", expr);}
ZI = expr:(&particle (z hieaou) &post_word) {return _node("ZI", expr);}


// MORPHOLOGY
// - Forein text quoting
foreign_quote_open = expr:(native_word) { _assign_foreign_quote_delim(expr); return _node("foreign_quote_open", expr); }
foreign_quote_word = expr:((!pause_char .)+) {return _node("foreign_quote_word", expr);}
foreign_quote_close = expr:(native_word) &{ return _is_foreign_quote_delim(expr); } { return _node("foreign_quote_close", expr); }

// - Compounds
compound = expr:((compound_2 / compound_3 / compound_n)) {return _node("compound", expr);}
compound_2 = expr:(e compound_word compound_word) {return _node("compound_2", expr);}
compound_3 = expr:(a compound_word compound_word compound_word) {return _node("compound_3", expr);}
compound_n = expr:(o (!compound_n_end compound_word)+ compound_n_end) {return _node("compound_n", expr);}
compound_n_end = expr:(spaces o spaces) {return _node("compound_n_end", expr);}
compound_word = expr:(spaces? (borrowing / native_word)) {return _node("compound_word", expr);}

// - Free-form words
freeform_variable = expr:(i (spaces &i / hyphen !i) freeform_content freeform_end) {return _node("freeform_variable", expr);}
borrowing = expr:(u (spaces &u / hyphen !u) freeform_content freeform_end) {return _node("borrowing", expr);}
freeform_content = expr:((initial_pair / consonant / h)? hieaou (consonant_cluster hieaou)* sonorant?) {return _node("freeform_content", expr);}
freeform_end = expr:((pause_char / space_char / EOF)) {return _node("freeform_end", expr);}

// - Native words
native_word = expr:(root / particle) {return _node("native_word", expr);}
particle = expr:(!sonorant particle_1 &post_word) {return _node("particle", expr);}
root = expr:(!sonorant (root_1 / root_2 / root_3) &post_word) {return _node("root", expr);}

particle_1 = expr:(consonant hieaou !medial_pair) {return _node("particle_1", expr);}

root_1 = expr:(consonant hieaou (hyphen (medial_pair / sonorant) hieaou)+ sonorant?) {return _node("root_1", expr);}
root_2 = expr:(consonant hieaou sonorant) {return _node("root_2", expr);}
root_3 = expr:(initial_pair hieaou (hyphen (medial_pair / sonorant) hieaou)* sonorant?) {return _node("root_3", expr);}

// - Legal clusters
hieaou = expr:(ieaou (hyphen h ieaou)*) {return _node("hieaou", expr);}
ieaou = expr:(vowel (hyphen vowel)*) {return _node("ieaou", expr);}

consonant_cluster = expr:((consonant_cluster_1 / consonant_cluster_2) !consonant) {return _node("consonant_cluster", expr);}
consonant_cluster_1 = expr:(hyphen &medial_pair consonant initial_pair / hyphen medial_pair) {return _node("consonant_cluster_1", expr);}
consonant_cluster_2 = expr:(sonorant? hyphen (initial_pair / consonant) / sonorant hyphen) {return _node("consonant_cluster_2", expr);}

medial_pair = expr:(!initial_pair &medial_patterns consonant consonant !consonant) {return _node("medial_pair", expr);}
medial_patterns = expr:((medial_n / medial_fv / medial_plosive)) {return _node("medial_patterns", expr);}
medial_n = expr:((m / liquid) n / n liquid) {return _node("medial_n", expr);}
medial_fv = expr:((f / v) (plosive / sibilant / m)) {return _node("medial_fv", expr);}
medial_plosive = expr:(plosive (f / v / plosive / m)) {return _node("medial_plosive", expr);}

initial_pair = expr:(&initial consonant consonant !consonant) {return _node("initial_pair", expr);}
initial = expr:(((plosive / f / v) sibilant / sibilant? other? sonorant?) !consonant) {return _node("initial", expr);}

other = expr:((p / b) !n / (t / d) !n !l / v / f / k / g / m / n !liquid) {return _node("other", expr);}
plosive = expr:(t / d / k / g / p / b) {return _node("plosive", expr);}
sibilant = expr:(c / s / j / z) {return _node("sibilant", expr);}
sonorant = expr:(n / r / l) {return _node("sonorant", expr);}

consonant = expr:((voiced / unvoiced / liquid / nasal)) {return _node("consonant", expr);}
nasal = expr:(m / n) {return _node("nasal", expr);}
liquid = expr:(l / r) {return _node("liquid", expr);}
voiced = expr:(b / d / g / v / z / j) {return _node("voiced", expr);}
unvoiced = expr:(p / t / k / f / s / c) {return _node("unvoiced", expr);}

vowel = expr:(i / e / a / o / u) {return _node("vowel", expr);}

// Legal letters
i = expr:([iI]+ !i) {return ["i", "i"];} // <LEAF>
e = expr:([eE]+ !e) {return ["e", "e"];} // <LEAF>
a = expr:([aA]+ !a) {return ["a", "a"];} // <LEAF>
o = expr:([oO]+ !o) {return ["o", "o"];} // <LEAF>
u = expr:([uU]+ !u) {return ["u", "u"];} // <LEAF>

h = expr:([hH]+ !h) {return ["h", "h"];} // <LEAF>
n = expr:([nN]+ !n) {return ["n", "n"];} // <LEAF>
r = expr:([rR]+ !r) {return ["r", "r"];} // <LEAF>
l = expr:([lL]+ !l) {return ["l", "l"];} // <LEAF>

m = expr:([mM]+ !m) {return ["m", "m"];} // <LEAF>
p = expr:([pP]+ !p !voiced) {return ["p", "p"];} // <LEAF>
b = expr:([bB]+ !b !unvoiced) {return ["b", "b"];} // <LEAF>
f = expr:([fF]+ !f !voiced) {return ["f", "f"];} // <LEAF>
v = expr:([vV]+ !v !unvoiced) {return ["v", "v"];} // <LEAF>
t = expr:([tT]+ !t !voiced) {return ["t", "t"];} // <LEAF>
d = expr:([dD]+ !d !unvoiced) {return ["d", "d"];} // <LEAF>
s = expr:([sS]+ !s !c !voiced) {return ["s", "s"];} // <LEAF>
z = expr:([zZ]+ !z !j !unvoiced) {return ["z", "z"];} // <LEAF>
c = expr:([cC]+ !c !s !voiced) {return ["c", "c"];} // <LEAF>
j = expr:([jJ]+ !j !z !unvoiced) {return ["j", "j"];} // <LEAF>
g = expr:([gG]+ !g !unvoiced) {return ["g", "g"];} // <LEAF>
k = expr:([kK]+ !k !voiced) {return ["k", "k"];} // <LEAF>

// - Spaces / Pause
post_word = expr:((pause_char &vowel) / !sonorant &consonant / spaces) {return _node("post_word", expr);}
spaces = expr:(space_char+ hesitation? (pause_char &vowel)? / pause_char &vowel / EOF) {return _node("spaces", expr);}
hesitation = expr:((n (space_char+ / EOF))+) {return _node("hesitation", expr);}

// - Special characters
hyphen = expr:((hyphen_char [\n\r]*)?) {return _node("hyphen", expr);} // hyphens + line break support
hyphen_char = expr:([\u2010\u2014\u002D]) {return _node("hyphen_char", expr);}
pause_char = expr:((['’`]) !pause_char) {return _node("pause_char", expr);}
// space_char <- [\t\n\r\u0020?!.,;:<>()\[\]{}"“”«»„“] # ignore foreign punctuation
space_char = expr:(!(pause_char / digit / hyphen_char / vowel / consonant / h) .) {return _join(expr);}
digit = expr:([0123456789]) {return ["digit", expr];} // <LEAF2>
EOF = expr:(!.) {return _node("EOF", expr);}
