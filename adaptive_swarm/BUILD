for input_file in glob("*.yue"):
    base_name = input_file.removesuffix(".yue")
    out_file = base_name + ".lua"
    genrule(
        name = base_name,
        srcs = [input_file],
        outs = [out_file],
        cmd = "$(exe //:yue_build) $SRC $OUT",
        tools = "//:yue_build"
    )