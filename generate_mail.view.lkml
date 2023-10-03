
view: generate_mail {
  derived_table: {
    sql:
        SELECT
          @{generate_mail_primary_key}
          , prompt
          , ml_generate_text_result
          , ml_generate_text_status
        FROM ML.GENERATE_TEXT(
          MODEL `@{big_query_model_name_2}`, (
            SELECT
              @{generate_mail_primary_key}
              , CONCAT('You are a creative marketing professional. You only create marketing ]content and nothing else. For a customer whose name is ',@{generate_mail_name},' living in ', @{generate_mail_country}, ' and whose segment type is ',@{generate_mail_cohort},', create a personalized 2-3 line email about potential destinations in their country that will interest them based on their cohort. ') AS prompt
            FROM @{generate_mail_table_name} AS model_query
            ),
          STRUCT(
            {% if max_output_tokens._parameter_value > 1024 or max_output_tokens._parameter_value < 1 %} 50 {% else %} {% parameter max_output_tokens %} {% endif %} AS max_output_tokens
            , {% if temperature._parameter_value > 1 or temperature._parameter_value < 0 %} 1.0 {% else %} {% parameter temperature %} {% endif %} AS temperature
            , {% if top_k._parameter_value > 40 or top_k._parameter_value < 1 %} 40 {% else %} {% parameter top_k %} {% endif %} AS top_k
            , {% if top_p._parameter_value > 1 or top_p._parameter_value < 0 %} 1.0 {% else %} {% parameter top_p %} {% endif %} AS top_p
          )
        )
    ;;
  }

  parameter: prompt_input {
    label: " Prompt"
    type: string
    suggestions: [
      "Hyperpersonalized mail generation"

    ]
  }

  # https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-generate-text#arguments

  parameter: max_output_tokens {
    type: number
    default_value: "50"
    description: "max_output_tokens is an INT64 value in the range [1,1024] that sets the maximum number of tokens that the model outputs.
    Specify a lower value for shorter responses and a higher value for longer responses. The default is 50."
  }

  parameter: temperature {
    type: number
    default_value: "1.0"
    description: "temperature is a FLOAT64 value in the range [0.0,1.0] that is used for sampling during the response generation,
    which occurs when top_k and top_p are applied. It controls the degree of randomness in token selection. Lower temperature
    values are good for prompts that require a more deterministic and less open-ended or creative response, while higher
    temperature values can lead to more diverse or creative results. A temperature value of 0 is deterministic,
    meaning that the highest probability response is always selected. The default is 1.0."
  }

  parameter: top_k {
    type: number
    default_value: "40"
    description: "top_k is an INT64 value in the range [1,40] that changes how the model selects tokens for output.
    Specify a lower value for less random responses and a higher value for more random responses. The default is 40."
  }

  parameter: top_p {
    type: number
    default_value: "1.0"
    description: "top_p is a FLOAT64 value in the range [0.0,1.0] that changes how the model selects tokens for output.
    Specify a lower value for less random responses and a higher value for more random responses. The default is 1.0."
  }

  dimension: complaint_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.complaint_id ;;
  }

# ml_generate_text_result returns JSON object in following format:
#
# {
#   "predictions": [
#     {
#       "citationMetadata": { "citations": [] },
#       "content": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt...",
#       "safetyAttributes": { "blocked": false, "categories": [], "scores": [] }
#     }
#   ]
# }

  dimension:  text_result {
    type: string
    sql:  JSON_VALUE(${TABLE}.ml_generate_text_result, '$.predictions[0].content') ;;
    html:<div style="white-space:pre">{{value}}</div>;;
  }

  dimension:  blocked {
    type: string
    sql:  JSON_VALUE(${TABLE}.ml_generate_text_result, '$.predictions[0].safetyAttributes.blocked') ;;
    html:<div style="white-space:pre">{{value}}</div>;;
    group_label: "Safety Attributes"
  }

  dimension:  categories {
    type: string
    sql:  ARRAY_TO_STRING(JSON_VALUE_ARRAY(${TABLE}.ml_generate_text_result, '$.predictions[0].safetyAttributes.categories'), ', ') ;;
    html:<div style="white-space:pre">{{value}}</div>;;
    group_label: "Safety Attributes"
  }

  dimension:  scores {
    type: string
    sql:  ARRAY_TO_STRING(JSON_VALUE_ARRAY(${TABLE}.ml_generate_text_result, '$.predictions[0].safetyAttributes.scores'), ', ') ;;
    html:<div style="white-space:pre">{{value}}</div>;;
    group_label: "Safety Attributes"
  }

  dimension:  job_status {
    type: string
    sql:  ${TABLE}.ml_generate_text_status ;;
    html:<div style="white-space:pre">{{value}}</div>;;
  }

}
