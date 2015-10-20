package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"gohun"
	"io/ioutil"
	"log"
	"net/http"
	"path"
	"regexp"
	"strings"
)

const port = "8080"

var (
	goMap map[string]*gohun.Gohun = make(map[string]*gohun.Gohun)
	reWhiteSpace,
	reWord,
	reChunker *regexp.Regexp
	dictionaries *string
	lsResp       []byte
)

func init() {
	log.SetPrefix("gohunservice: ")

	reWhiteSpace = regexp.MustCompile(`^\s*$`)
	reWord = regexp.MustCompile(`^\w+$`)
	reChunker = regexp.MustCompile(`(\w+|\W+)`)

	dictionaries = flag.String("dictionaries", "", "dictionaries directory location.")
	flag.Parse()

	if dictionaries == nil || *dictionaries == "" {
		log.Fatal("gohunservice requires a dictionaries path be specified.")
	}

	dirs, err := ioutil.ReadDir(*dictionaries)
	logFatalError(err)

	var validDs []string = nil
	for _, dir := range dirs {
		if dir.IsDir() {
			name := dir.Name()
			validDs = append(validDs, `"`+name+`"`)
			goMap[name] = nil
		}
	}
	lsResp = append(lsResp, []byte(`[`)...)
	lsResp = append(lsResp, []byte(strings.Join(validDs, `,`))...)
	lsResp = append(lsResp, []byte(`]`)...)
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/listdictionaries", lsDictionaries)
	mux.HandleFunc("/listdictionaries/", lsDictionaries)
	mux.HandleFunc("/spellsuggest", spellSuggestHandler)
	mux.HandleFunc("/spellsuggest/", spellSuggestHandler)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal("Http failed to bind to port " + port + ", because: " + err.Error())
	}
}

func spellSuggestHandler(rw http.ResponseWriter, req *http.Request) {
	rw.Header().Set("Content-Type", "application/json")
	defer req.Body.Close()
	path := strings.Split(req.URL.Path, "/")
	if len(path) < 3 {
		rw.WriteHeader(405)
		fmt.Fprint(rw, `{"error":"you must specify a dictionary"}"`)
		return
	}
	dictionary := path[2]
	var goh *gohun.Gohun = nil
	var ok bool = false
	if goh, ok = goMap[dictionary]; !ok {
		rw.WriteHeader(405)
		fmt.Fprint(rw, `{"error":"invalid dictionary"}"`)
		return
	}
	if goh == nil {
		var loadError error = nil
		goh, loadError = loadDictionary(dictionary)
		if loadError != nil {
			rw.WriteHeader(500)
			fmt.Fprint(rw, `{"error":"unable to find valid dictionary, sorry"}"`)
			return
		}
	}
	query := req.URL.Query()
	phrase := query["phrase"]
	if phrase != nil && len(phrase) > 0 && !reWhiteSpace.MatchString(phrase[0]) {
		_, err := fmt.Fprint(rw, `{"correct":`)
		b, res := getSuggestion(goh, phrase[0])
		enc := json.NewEncoder(rw)
		err = enc.Encode(b)
		logError(err)
		_, err = fmt.Fprint(rw, `,"from":`)
		logError(err)
		err = enc.Encode(phrase[0])
		logError(err)
		_, err = fmt.Fprint(rw, `,"suggestion":`)
		logError(err)
		err = enc.Encode(res)
		logError(err)
		_, err = fmt.Fprint(rw, `}`)
		logError(err)

	} else {
		_, err := fmt.Fprint(rw, `{"correct":true,"from":null}`)
		logError(err)
	}
}

func lsDictionaries(rw http.ResponseWriter, req *http.Request) {
	rw.Header().Set("Content-Type", "application/json")
	defer req.Body.Close()
	rw.Write(lsResp)
}

func getSuggestion(goh *gohun.Gohun, phrase string) (bool, string) {
	chunks := reChunker.FindAllString(phrase, -1)
	l := len(chunks)
	c := make(chan int, l)
	cP := &chunks
	for i := 0; i < l; i++ {
		if reWord.MatchString(chunks[i]) {
			go parseSuggestion(goh, cP, i, c)
		} else {
			c <- 0
		}
	}
	t := 0
	for i := 0; i < l; i++ {
		t += <-c
	}
	close(c)
	return t == 0, strings.Join(chunks, "")
}

func parseSuggestion(goh *gohun.Gohun, chunks *[]string, i int, c chan int) {
	r := 0
	if b, _, res := goh.CheckSuggestions((*chunks)[i]); !b {
		r = 1
		if len(res) > 0 {
			(*chunks)[i] = res[0]
		}
	}
	c <- r
}

func loadDictionary(dictionary string) (*gohun.Gohun, error) {
	dicChan := make(chan readFileResp)
	affChan := make(chan readFileResp)

	go readFile(path.Join(*dictionaries, dictionary, dictionary+".dic"), dicChan)
	go readFile(path.Join(*dictionaries, dictionary, dictionary+".aff"), affChan)

	dResp := <-dicChan
	if dResp.err != nil {
		return nil, dResp.err
	}
	aResp := <-affChan
	if aResp.err != nil {
		return nil, aResp.err
	}

	goh := gohun.NewGohun(*aResp.file, *dResp.file)
	goMap[dictionary] = goh
	return goh, nil
}

type readFileResp struct {
	err  error
	file *[]byte
}

func readFile(file string, c chan readFileResp) {
	bytes, err := ioutil.ReadFile(file)
	resp := readFileResp{}
	resp.err = err
	resp.file = &bytes
	c <- resp
}

func logFatalError(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func logError(err error) {
	if err != nil {
		go log.Println(err.Error())
	}
}
