from glob import glob
import os
from pprint import pprint

names = []

for svg_fp in glob("/Users/mlevental/dev_projects/makslevental.github.io/images/memory_planning/*.svg"):
    # if "small_bert" in svg_fp:
    #     svg_fp = svg_fp.replace("small_bert", "smallbert")

    # model_name, strat = os.path.split(svg_fp)[-1].split("_", 1)
    # static_or_profile, fp = strat.split("_", 1)
    # name = os.path.splitext(fp)[0].replace("_", " ")
    # names.append((name, static_or_profile, fp))
    # print(names[-1])
    fn = os.path.split(svg_fp)[-1]
    names.append((fn.replace(".svg", "").replace("_", " ").replace("small bert", "small_bert"), fn))

# <ul>
#     <li><a href="#tldr">TL;DR</a></li>
#     <li><a href="#background">Background</a></li>
#     <li><a href="#greedy-strategies-for-memory-planning">Greedy Strategies for Memory Planning</a></li>
#     <li><a href="#results">Results</a></li>
#     <li><a href="#footnotes">Footnotes</a></li>
# </ul>

# <object data="corner_case.svg" type="image/svg+xml"></object>
# <h1 id="tldr">TL;DR</h1>

names = sorted(names)
with open("index.html" , "w") as f:
    f.write("<html>\n")
    f.write("<ul>\n")
    f.write("""
    <li><a href='#memory_usage_for_strats_and_models_for_profiled_plans'>memory usage for strats and models for profiled plans</a></li>
    <li><a href='#memory_usage_for_strats_and_models_for_static_plans'>memory usage for strats and models for static plans</a></li>
    """)

    for name, fp in names:
        if "memory usage" in name: continue
        f.write(f"""<li><a href='#{fp.replace(".svg", "")}'>{name}</a></li>\n""")
    f.write("</ul>\n\n")

    f.write("""
    <h1 id="memory_usage_for_strats_and_models_for_profiled_plans">memory usage for strats and models for profiled plans</h1>
    <object data="memory_usage_for_strats_and_models_for_profiled_plans.svg" type="image/svg+xml"></object>
    <p></p>

    <h1 id="memory_usage_for_strats_and_models_for_static_plans">memory usage for strats and models for static plans</h1>
    <object data="memory_usage_for_strats_and_models_for_static_plans.svg" type="image/svg+xml"></object>
    <p></p>
    """)

    for name, fp in names:
        if "memory usage" in name: continue
        f.write(f"""<h1 id="{fp.replace(".svg", "")}">{name}</h1>\n""")
        f.write(f"""<object data="{fp}" type="image/svg+xml"></object>\n""")
        f.write("<p></p>\n\n")

    f.write("<html>\n")


