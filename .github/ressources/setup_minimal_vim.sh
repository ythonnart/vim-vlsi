echo "Install default .vimrc"
cp $GITHUB_WORKSPACE/runtime/vim-vlsim/.github/ressources/vimrc ~/.vimrc

echo "Install Pathogen"
mkdir -p ~/.vim ~/.vim/autoload 
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

echo "Link ~/.vim/bundle to ./runtime"
ln -s $GITHUB_WORKSPACE/runtime/ ~/.vim/bundle

echo "Content of vimrc"
cat ~/.vimrc

echo "content of .vim"
tree ~/.vim
