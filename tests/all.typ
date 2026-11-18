// Every diagram once, a page each: tests/run.sh checks that it lays out in one
// iteration, bench/run.sh times it.
#import "samples.typ": samples
#set page(width: 18cm, height: auto, margin: 1cm)

#for sample in samples.values() {
  sample
  pagebreak(weak: true)
}
