connection: "sudipto-google-trends"

include: "./*.view.lkml"

datagroup: consumer_complaint_database_default_datagroup {
  max_cache_age: "1 hour"
}

persist_with: consumer_complaint_database_default_datagroup

explore: complaint_database {
  always_filter: {
    filters: [
      generate_text.prompt_input: "",
      generate_text.max_output_tokens: "100",
      generate_text.temperature: "0.1",
      generate_text.top_k: "40",
      generate_text.top_p: "0.8"
    ]
  }
  join: generate_text {
    type: left_outer
    relationship: one_to_one
    sql_on: complaint_database.@{generate_text_primary_key} = generate_text.@{generate_text_primary_key} ;;
  }
}

explore: user_data {
  always_filter: {
    filters: [
      generate_mail.prompt_input: "",
      generate_mail.max_output_tokens: "100",
      generate_mail.temperature: "0.1",
      generate_mail.top_k: "40",
      generate_mail.top_p: "0.8"
    ]
  }
  join: generate_mail {
    type: left_outer
    relationship: one_to_one
    sql_on: complaint_database.@{generate_mail_primary_key} = generate_text.@{generate_mail_primary_key} ;;
  }
}
