'''
    Renders a blue triangle
'''

import numpy as np
import os
import moderngl_window as mglw


class Example(mglw.WindowConfig):
    gl_version = (3, 3)
    title = "ModernGL Example"
    window_size = (1280, 720)
    aspect_ratio = 16 / 9
    resizable = True

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    @classmethod
    def run(cls):
        mglw.run_window_config(cls)



class HelloWorld(Example):
    gl_version = (3, 3)
    title = "Hello World"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.prog = self.ctx.program(
            vertex_shader= open('vert.glsl', 'r').read(),
            # fragment_shader= open('frag.glsl', 'r').read()
            # fragment_shader= open('sdfs/001_2d_sdf_playground.glsl', 'r').read()
            fragment_shader = open('sdfs/002_wing.glsl', 'r').read()
        )

        self.prog['iResolution'] = self.window_size;

        # vertices = np.array([
        #     0.0, 0.8,
        #     -0.6, -0.8,
        #     0.6, -0.8,
        # ], dtype='f4')

        vertices = np.array([
            -1.0, 1.0,
            -1.0, -1.0, 
            1.0, 1.0,
            1.0, 1.0,
            1.0, -1.0, 
            -1.0, -1.0
        ], dtype='f4')

        self.vbo = self.ctx.buffer(vertices)
        self.vao = self.ctx.simple_vertex_array(self.prog, self.vbo, 'in_vert')

    def render(self, time, frame_time):
        # self.prog['iTime'] = 1.0
        self.prog['iTime'] = time
        self.ctx.clear(1.0, 1.0, 1.0)
        self.vao.render()


if __name__ == '__main__':
    HelloWorld.run()
