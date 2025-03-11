/**
* Concept Idea by : Jayaprakash
**/

REPORT z_auto_geo_prompt.

DATA: gv_postal_code TYPE string,
      gv_city TYPE string,
      gv_country TYPE string,
      gv_latitude TYPE string,
      gv_longitude TYPE string,
      gv_response TYPE string.

PARAMETERS: p_postcode TYPE string OBLIGATORY.

START-OF-SELECTION.

  " Capture User Entry
  gv_postal_code = p_postcode.

  " Fetch Geo-Location Data
  PERFORM get_geolocation USING gv_postal_code CHANGING gv_city gv_country gv_latitude gv_longitude.

  " Validate Response
  IF gv_city IS NOT INITIAL AND gv_country IS NOT INITIAL.
    WRITE: / 'Location Found:', gv_city, gv_country.
    WRITE: / 'Coordinates:', gv_latitude, gv_longitude.
  ELSE.
    MESSAGE 'Invalid postal code. Please enter a valid one!' TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------
* Fetch Geo-Location Data (Using External API)
*---------------------------------------------------------------
FORM get_geolocation USING lv_postal_code TYPE string
                      CHANGING lv_city TYPE string
                               lv_country TYPE string
                               lv_latitude TYPE string
                               lv_longitude TYPE string.

  DATA: lv_url TYPE string,
        lv_json_response TYPE string,
        lt_json_data TYPE TABLE OF string,
        lo_http_client TYPE REF TO if_http_client.

  " Construct API Request URL (Example using OpenStreetMap API)
  CONCATENATE 'https://nominatim.openstreetmap.org/search?postalcode='
              lv_postal_code '&format=json' INTO lv_url.

  " Create HTTP Client
  CALL METHOD cl_http_client=>create_by_url
    EXPORTING url = lv_url
    IMPORTING client = lo_http_client.

  " Send HTTP Request
  lo_http_client->send( ).
  lo_http_client->receive( ).

  " Capture Response
  lv_json_response = lo_http_client->response->get_cdata( ).

  " Parse JSON Response
  TRY.
      DATA(lo_json) = /ui2/cl_json=>deserialize( json = lv_json_response ).
      READ TABLE lo_json->data INTO lv_city INDEX 1 TRANSPORTING NO FIELDS.
      READ TABLE lo_json->data INTO lv_country INDEX 2 TRANSPORTING NO FIELDS.
      READ TABLE lo_json->data INTO lv_latitude INDEX 3 TRANSPORTING NO FIELDS.
      READ TABLE lo_json->data INTO lv_longitude INDEX 4 TRANSPORTING NO FIELDS.
  CATCH cx_root INTO DATA(lo_error).
      MESSAGE 'Error in fetching geolocation' TYPE 'E'.
  ENDTRY.

ENDFORM.
