module Request.Helpers exposing (apiUrl)


apiUrl : String -> String
apiUrl str =
    "localhost:4000/api" ++ str
