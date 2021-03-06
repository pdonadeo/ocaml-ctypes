(*
 * Copyright (c) 2014 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(** Operations for generating C bindings stubs. *)

module Types :
sig
  module type TYPE =
  sig
    include Ctypes_types.TYPE

    type 'a const
    val constant : string -> 'a typ -> 'a const
    (** [constant name typ] retrieves the value of the compile-time constant
        [name] of type [typ].  It can be used to retrieve enum constants,
        #defined values and other integer constant expressions.

        The type [typ] must be either an integer type such as [bool], [char],
        [int], [uint8], etc., or a view (or perhaps multiple views) where the
        underlying type is an integer type.

        When the value of the constant cannot be represented in the type there
        will typically be a diagnostic from either the C compiler or the OCaml
        compiler.  For example, gcc will say

           warning: overflow in implicit constant conversion *)

    val enum : string -> ?unexpected:(int64 -> 'a) -> ('a * int64 const) list -> 'a typ
    (** [enum name ?unexpected alist] builds a type representation for the
        enum named [name].  The size and alignment are retrieved so that the
        resulting type can be used everywhere an integer type can be used: as
        an array element or struct member, as an argument or return value,
        etc.

        The value [alist] is an association list of OCaml values and values
        retrieved by the [constant] function.  For example, to expose the enum

          enum letters { A, B, C = 10, D }; 

        you might first retrieve the values of the enumeration constants:

          let a = constant "A" int64_t
          and b = constant "B" int64_t
          and c = constant "C" int64_t
          and d = constant "D" int64_t

        and then build the enumeration type

          let letters = enum "letters" [
             `A, a;
             `B, b;
             `C, c;
             `D, d;
          ] ~unexpected:(fun i -> `E i)

        The [unexpected] function specifies the value to return in the case
        that some unexpected value is encountered -- for example, if a
        function with the return type 'enum letters' actually returns the
        value [-1]. *)
  end

  module type BINDINGS = functor (F : TYPE) -> sig end

  val write_c : Format.formatter -> (module BINDINGS) -> unit
end


module type FOREIGN =
sig
  type 'a fn
  val foreign : string -> ('a -> 'b) Ctypes.fn -> ('a -> 'b) fn
  val foreign_value : string -> 'a Ctypes.typ -> 'a Ctypes.ptr fn
end

module type BINDINGS = functor (F : FOREIGN with type 'a fn = unit) -> sig end

val write_c : Format.formatter -> prefix:string -> (module BINDINGS) -> unit
(** [write_c fmt ~prefix bindings] generates C stubs for the functions bound
    with [foreign] in [bindings].  The stubs are intended to be used in
    conjunction with the ML code generated by {!write_ml}.

    The generated code uses definitions exposed in the header file
    [cstubs_internals.h].
*)

val write_ml : Format.formatter -> prefix:string -> (module BINDINGS) -> unit
(** [write_ml fmt ~prefix bindings] generates ML bindings for the functions
    bound with [foreign] in [bindings].  The generated code conforms to the
    {!FOREIGN} interface.

    The generated code uses definitions exposed in the module
    [Cstubs_internals]. *)

