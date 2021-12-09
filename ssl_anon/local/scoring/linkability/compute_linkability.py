from performance import linkability, draw_scores
import argparse
import pandas


parser = argparse.ArgumentParser(description='Computing the global linkability measure for a list of linkage function score')
parser.add_argument('-s', dest='score_file', type=str, nargs=1, required=True, help='path to score file')
parser.add_argument('-k', dest='key_file', type=str, nargs=1, required=True,  help='path to key file')
parser.add_argument('--omega', dest='omega', type=float, nargs=1, required=False, default=1,   help='prior ratio (default is 1)')
parser.add_argument('-d', dest='draw_scores', action='store_true', help='flag: draw the score distribution in a figure')
parser.add_argument('-o', dest='output_file', type=str, nargs=1, required=False,   help='output path of the png and pdf file (default is linkability_<score_file>)')



args = parser.parse_args()
# args = parser.parse_args('-s scores.txt -k key.txt'.split(' '))
# args = parser.parse_args('-s scores.txt -k key.txt -e'.split(' '))

scr = pandas.read_csv(args.score_file[0], sep=' ', header=None).pivot_table(index=0, columns=1, values=2)
key = pandas.read_csv(args.key_file[0], sep=' ', header=None).replace('nontarget', False).replace('target', True).pivot_table(index=0, columns=1, values=2)

matedScores = scr.values[key.values == True]
nonMatedScores = scr.values[key.values == False]

Dsys, D, bin_centers, bin_edges  = linkability(matedScores, nonMatedScores, args.omega)

if args.draw_scores:
  output_file= "linkability_"+args.score_file[0]
  if args.output_file is not None:
    output_file = args.output_file[0]
  draw_scores(matedScores, nonMatedScores, Dsys, D, bin_centers, bin_edges, output_file)



print("linkability: %f" % (Dsys))
print("")
