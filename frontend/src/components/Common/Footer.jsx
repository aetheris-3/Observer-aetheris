import React from 'react';
import { Github, Code2, Heart } from 'lucide-react';

const Footer = () => {
    return (
        <footer className="w-full bg-[#0f111a] border-t border-white/5 py-8 mt-auto">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex flex-col items-center justify-center space-y-6">

                    {/* Logo/Brand Area - Optional, keeping it subtle as per request */}
                    <div className="flex items-center space-x-2 text-white/90 hover:text-white transition-colors duration-300">
                        <Code2 className="w-5 h-5 text-indigo-400" />
                        <span className="text-lg font-semibold tracking-wide">Aetheris</span>
                    </div>

                    {/* Developer Section */}
                    <div className="flex flex-col items-center space-y-2 text-center">
                        <p className="text-sm text-gray-400 font-medium">Developed by</p>
                        <div className="flex flex-wrapjustify-center gap-x-6 gap-y-2 text-sm text-gray-300">
                            <span className="hover:text-indigo-400 transition-colors duration-200 cursor-default">Sumit Mewada</span>
                            <span className="hidden sm:inline w-1 h-1 bg-gray-600 rounded-full self-center"></span>
                            <span className="hover:text-indigo-400 transition-colors duration-200 cursor-default">Satyanarayan Chouhan</span>
                            <span className="hidden sm:inline w-1 h-1 bg-gray-600 rounded-full self-center"></span>
                            <span className="hover:text-indigo-400 transition-colors duration-200 cursor-default">Divyansh Shukla</span>
                        </div>
                    </div>

                    {/* Links Section */}
                    <div className="flex items-center space-x-6">
                        <a
                            href="https://github.com/aetheris-3"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="group flex items-center space-x-2 text-gray-400 hover:text-white transition-all duration-300"
                        >
                            <div className="p-2 rounded-full bg-white/5 group-hover:bg-white/10 transition-colors">
                                <Github className="w-5 h-5" />
                            </div>
                            <span className="text-sm font-medium group-hover:tracking-wide transition-all">GitHub</span>
                        </a>
                    </div>

                    {/* Copyright Section */}
                    <div className="pt-4 border-t border-white/5 w-full text-center">
                        <p className="text-xs text-gray-500 flex items-center justify-center gap-1">
                            &copy; 2026 Aetheris. All rights reserved.
                            <span className="mx-1">&middot;</span>
                            <span className="flex items-center gap-1">
                                Made with <Heart className="w-3 h-3 text-red-500 fill-red-500 animate-pulse" /> for builders
                            </span>
                        </p>
                    </div>
                </div>
            </div>
        </footer>
    );
};

export default Footer;
