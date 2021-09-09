*&---------------------------------------------------------------------*
*& Report Z_DEMO_NEW_SYNTAX
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z_demo_new_syntax.

TABLES: ekko.
SELECT-OPTIONS: s_ebeln FOR ekko-ebeln, s_date FOR ekko-aedat.

*-simple select query to join ekko and ekpo entries
SELECT a~ebeln,
b~ebelp,
b~menge
FROM ekko AS a INNER JOIN ekpo AS b
ON a~ebeln = b~ebeln
WHERE a~ebeln IN @s_ebeln
AND   a~aedat IN @s_date
ORDER BY a~ebeln, b~ebelp
INTO TABLE @DATA(lt_ekko1).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Simple Join' ).
  cl_demo_output=>write_data( lt_ekko1 ).
ENDIF.

*-select count from ekpo based on ebeln
SELECT ebeln,
COUNT(*) AS count
FROM ekpo
WHERE ebeln IN @s_ebeln
AND aedat IN @s_date
GROUP BY ebeln
INTO TABLE @DATA(lt_ekko2).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Count' ).
  cl_demo_output=>write_data( lt_ekko2 ).
ENDIF.

*-select query for aggregation sum, max and min
SELECT a~ebeln,
SUM( b~menge ) AS sum_menge,
MAX( b~menge ) AS max_menge,
MIN( b~menge ) AS min_menge
FROM ekko AS a INNER JOIN ekpo AS b
ON a~ebeln = b~ebeln
WHERE a~ebeln IN @s_ebeln
AND a~aedat IN @s_date
GROUP BY a~ebeln
INTO TABLE @DATA(lt_ekko4).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Aggregation Sum, Max, Min' ).
  cl_demo_output=>write_data( lt_ekko4 ).
ENDIF.

*-other frequently used aggregation
SELECT a~ebeln,
b~ebelp,
lower( a~ernam ) AS lower_ernam,
upper( a~ernam ) AS upper_ernam,
length( a~ernam ) AS length_ernam,
substring( a~ernam, 2, 3 ) AS substring,
a~lifnr,
ltrim( a~lifnr, '0' ) AS ltrim_lifnr,
concat_with_space( CAST( b~menge AS CHAR ) , a~waers, 1 ) AS amount
FROM ekko AS a INNER JOIN ekpo AS b
ON a~ebeln = b~ebeln
WHERE a~ebeln IN @s_ebeln
AND   a~aedat IN @s_date
GROUP BY a~ebeln,a~ernam,a~lifnr, b~ebelp, a~zterm, b~menge, a~waers
INTO TABLE @DATA(lt_ekko3).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Other Aggregations' ).
  cl_demo_output=>write_data( lt_ekko3 ).
ENDIF.

*-case statement in select query
SELECT a~ebeln,
b~ebelp,
CASE WHEN b~menge LE 10 THEN 'LESS'
WHEN b~menge GT 10 THEN 'MORE' END AS menge
FROM ekko AS a INNER JOIN ekpo AS b
ON a~ebeln = b~ebeln
WHERE a~ebeln IN @s_ebeln
AND   a~aedat IN @s_date
ORDER BY a~ebeln, b~ebelp
INTO TABLE @DATA(lt_ekko7).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Case in Select Query' ).
  cl_demo_output=>write_data( lt_ekko7 ).
ENDIF.

*-read internal table to work area using value operator
TRY.
    DATA(ls_ekko5) = VALUE #( lt_ekko1[ ebelp = '00010' ] ).
    cl_demo_output=>write_text( 'Used Value operator and filtered only line item 10' ).
    cl_demo_output=>write_data( ls_ekko5 ).
  CATCH cx_sy_itab_line_not_found INTO DATA(ls_exp).
    DATA(lv_text) = ls_exp->get_text( ).
    cl_demo_output=>write_text( lv_text ).
ENDTRY.

DATA(lt_ekko6) = lt_ekko1.
CLEAR lt_ekko6.

*-corresponding operator
cl_demo_output=>write_text( 'Used corresponding operator and avoided transporting Menge' ).
lt_ekko6 = CORRESPONDING #( lt_ekko1  EXCEPT menge ).
cl_demo_output=>write_data( lt_ekko6 ).

*-fetch ekpo document and quantity
SELECT ebeln,
SUM( menge ) AS menge
FROM ekpo
WHERE ebeln IN @s_ebeln
AND   aedat IN @s_date
GROUP BY ebeln
INTO TABLE @DATA(lt_ekko8).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'EKPO Quantity' ).
  cl_demo_output=>write_data( lt_ekko8 ).
ENDIF.

*-fetch ekbe document and quantity
SELECT ebeln,
SUM( menge ) AS menge
FROM ekbe
WHERE ebeln IN @s_ebeln
GROUP BY ebeln
INTO TABLE @DATA(lt_ekko9).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'EKBE Quantity' ).
  cl_demo_output=>write_data( lt_ekko9 ).
ENDIF.

*-subtract ekbe quantity from ekpo quantity in select query
SELECT a~ebeln,
SUM( a~menge - b~menge ) AS menge
FROM ekpo AS a INNER JOIN ekbe AS b
ON a~ebeln = b~ebeln
WHERE a~ebeln IN @s_ebeln
AND   a~aedat IN @s_date
GROUP BY a~ebeln
INTO TABLE @DATA(lt_ekko10).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'EKPO - EKBE Quantity in select query' ).
  cl_demo_output=>write_data( lt_ekko10 ).
ENDIF.

DATA(lt_ekko11) =  lt_ekko8.

*-subtract ekbe quantity from ekpo quantity using reduce operator
LOOP AT lt_ekko11 ASSIGNING FIELD-SYMBOL(<lfs_ekpo>).

  <lfs_ekpo>-menge = REDUCE menge_d( INIT x = <lfs_ekpo>-menge FOR ls1 IN lt_ekko9 WHERE ( ebeln = <lfs_ekpo>-ebeln  )
  NEXT x = x - ls1-menge ).

ENDLOOP.
cl_demo_output=>write_text( 'EKPO - EKBE Quantity using REDUCE' ).
cl_demo_output=>write_data( lt_ekko11 ).


*-union and union all in select query
SELECT ebeln,
SUM( menge ) AS menge
FROM ekpo
WHERE ebeln IN @s_ebeln
GROUP BY ebeln
UNION
*UNION ALL

SELECT ebeln,
SUM( menge ) AS menge
FROM ekbe
WHERE ebeln IN @s_ebeln
GROUP BY ebeln

INTO TABLE @DATA(lt_ekko12).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'EKPO and EKBE Union ' ).
  cl_demo_output=>write_data( lt_ekko12 ).
ENDIF.


*-using select in internal tables
SELECT ebeln,
SUM( menge ) AS menge
FROM @lt_ekko1 AS lt_ekko1
GROUP BY ebeln
INTO TABLE @DATA(lt_ekko13).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'Select internal table lt_ekko1' ).
  cl_demo_output=>write_data( lt_ekko13 ).
ENDIF.

*-join internal table lt_ekko8 and standard table EKBE
SELECT a~ebeln,
a~menge AS ekpo_menge,
b~menge AS ekbe_menge
FROM @lt_ekko8 AS a INNER JOIN ekbe AS b
ON a~ebeln = b~ebeln
GROUP BY a~ebeln, a~menge, b~menge
INTO TABLE @DATA(lt_ekko14).
IF sy-subrc EQ 0.
  cl_demo_output=>write_text( 'join standard table EKBE and internal table lt_ekko1' ).
  cl_demo_output=>write_data( lt_ekko14 ).
ENDIF.


cl_demo_output=>display( ).
