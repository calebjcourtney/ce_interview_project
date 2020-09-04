/*
Simple implementation of an tf-idf.

As was described in the required documentation, this expects an input from stdin,
however I also added the ability to just pass the words in via args at the runtime command

For example,
./ce_interview_project
>his head a flag

can simply be run with:
./ce_interview_project his head a flag

They should result in the same output.

TF-IDF was used because it helps value words with a higher uniqueness.

So in the instance of "his head a flag",
we get a good value on "flag", since it is only used once in the poem.
The same goes for "head", also only used on the given line.

At the same time, "his" is used 29 times, while "a" is used 26 times.
Given how common these two words are, they should not be valued as highly as the other less common words for determining which line in the poem we get back.

Process Explanation:

There are two different sections: (1) the corpus and document building section and (2) the matching section.
Ideally the first would be processed once, up front and probably loaded into a sqlite database for quick access of the data. Given the size of this poem though, it's not really a problem to run this each time.

1. Corpus and document building:
    - iterates through each line of the poem
    - cleans the line, counts the percent of times a word is used in the line as a proxy for line importance
    - for each unique word found in the document (line), makes record of that word in the corpus
    - finally, convert the words of the corpus into a proxy for their importance by taking the log10 of (the total number of records divided by the number of records that word is found in
2. Matching from the input text
    - we use the same process as above to clean the input string
    - multiply the unique words from the input by the corpus importance from step 1.4
    - map each unique word to each line it is found in the corpus
    - each line in the corpus (if it has a corresponding word) receives a relevance score for the word relevance * corpus importance * input importance


This process actually has the added benefit of being able to weight certain input words as being more important than others.
For example, `./ce_interview_project his head a flag` results in a score of ~`0.66`
`./ce_interview_project his head head head a flag flag flag` results in a score of ~`0.54`


Opportunities for improvement:
The first thing that comes to mind is support for UTF-8 characters. The function `cleanSplitText` removes anything that is non-ascii, replacing it with a space.
So in the line: `They veil the plumèd lions on the galleys of St. Mark;`, `plumèd` turnes into `["plum", "d"]`

So if you do a search for `plumèd`, it will give you the correct result, but if you look for `plumed`, then it would give you an incorrect result.

This is why I think deeper support for UTF-8 characters would be helpful, depending on how much of a priority it should be.

Another area for improvement would be improving the scoring factor.
I think it would be good to have something along the lines of a probability that the output is correct.
*/


import std.algorithm;
import std.array;
import std.conv;
import std.regex;
import std.stdio;
import std.string;
import std.typecons;

import std.ascii: isAlpha, isWhite;
import std.math: log10;


void main(string[] args)
{
    auto file = File("lepanto.txt", "r");
    string[] raw_data;

    double[string][] clean_data;
    int[][string] word_map;
    double[string] corpus_weight;

    int num_lines;
    while (!file.eof()) {
        string line = file.readln().strip();
        if (line.length == 0)
            continue;

        raw_data ~= line;
        double[string] cleaned = cleanSplitText(line);
        clean_data ~= cleaned;

        foreach (key; cleaned.keys)
        {
            if (word_map.keys.canFind(key))
                word_map[key] ~= num_lines;
            else
                word_map[key] = [num_lines];

            if (!corpus_weight.keys.canFind(key))
                corpus_weight[key] = 1;
            else
                corpus_weight[key] += 1;
        }
        ++num_lines;
    }

    double totalDocs = clean_data.length.to!double;

    foreach (key; corpus_weight.keys)
        corpus_weight[key] = log10(totalDocs / corpus_weight[key]);

    string arguments;
    if (args.length > 1)
        arguments = args[1 .. $].join(" ");
    else
    {
        write(">");
        arguments = stdin.readln();
    }

    double[string] clean_in_string = cleanSplitText(arguments);

    double[int] output;
    // how important are the words in the given input
    double[string] wordWeights;
    foreach (key; clean_in_string.keys)
    {
        // we have no way to analyze that particular word
        // potentially work in a way to keep that value as part of the analysis somehow
        if (!corpus_weight.keys.canFind(key))
            continue;

        // weight in the phrase times the weight in the corpus
        wordWeights[key] = clean_in_string[key] * corpus_weight[key] * clean_in_string.length;

        foreach (index; word_map[key])
        {
            if (!output.keys.canFind(index))
                output[index] = wordWeights[key] * clean_data[index][key];
            else
                output[index] = output[index] + (wordWeights[key] * clean_data[index][key]);
        }
    }

    // find the index of the record with the highest resulting score
    int index;
    double highestScore = 0;
    foreach(i; output.byKeyValue)
    {
        if (i.value > highestScore)
        {
            highestScore = i.value;
            index = i.key;
        }
    }

    // score comparison as percent against other results - not currently returned anywhere, but could be
    //writeln(Tuple!(double, string)(highestScore, raw_data[index]));

    // 0 is the arbitrary benchmark - basically, we found some similarity
    // could also add a higher level of benchmark, assuming we wanted a certain level of confidence
    if (highestScore > 0)
        writeln(raw_data[index]);
    else
        writeln("no match");

}


double[string] cleanSplitText(string input)
{
    // todo: the word "plumèd" (non-ascii character) gets turned into "plum d" in the string
    auto re = ctRegex!(`[^a-zA-Z\s]`);
    double[string] cleanLine = input
                               .replaceAll(re, " ")
                               .map!(x => x.toLower)
                               .to!string
                               .split
                               .group
                               .map!(x => Tuple!(string, double)(x[0], x[1]))
                               .assocArray;

    double totalWords = cleanLine.values.sum;

    foreach (key; cleanLine.keys)
        cleanLine[key] /= totalWords;

    return cleanLine;
}
